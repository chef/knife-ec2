#
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require File.expand_path('../../spec_helper', __FILE__)

describe Chef::Knife::Cloud::Ec2ServerCreate do

  before do
    @knife_ec2_create = Chef::Knife::Cloud::Ec2ServerCreate.new
    {
      :aws_access_key_id => 'aws_access_key_id',
      :aws_secret_access_key => 'aws_secret_access_key',
      :region => "region",
      :server_create_timeout => 1000
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @ec2_service = Chef::Knife::Cloud::Ec2Service.new
    @ec2_service.stub(:msg_pair)
    @ec2_service.stub(:print)
    @knife_ec2_create.stub(:create_service_instance).and_return(@ec2_service)
    @knife_ec2_create.stub(:puts)
    @new_ec2_server = double()

    @ec2_server_attribs = { :tags => {'Name' =>  'Mock Server'},
                            :id => 'id-123456',
                            :key_name => 'key_name',
                            :flavor_id => 'flavor_id',
                            :groups  => [],
                            :image_id => 'image_id',
                            :dns_name  => 'dns_name',
                            :availability_zone => 'availability_zone',
                            :public_ip_address => '75.101.253.10',
                            :private_ip_address => '10.251.75.20',
                            :security_group_ids => [],
                            :private_dns_name => 'private_dns_name',
                            :placement_group => 'placement_group',
                            :root_device_type => 'root_device_type'
                          }

    @ec2_server_attribs.each_pair do |attrib, value|
      @new_ec2_server.stub(attrib).and_return(value)
    end
  end

  describe "run" do
    before(:each) do
      @knife_ec2_create.stub(:validate_params!)
      Fog::Compute::AWS.stub_chain(:new, :servers, :create).and_return(@new_ec2_server)
      @new_ec2_server.stub(:wait_for)
      @knife_ec2_create.stub(:ami).and_return("")
      @knife_ec2_create.ami.stub(:root_device_type)
      @knife_ec2_create.stub(:create_tags) 
      @knife_ec2_create.stub(:ui).and_return(double)
      @knife_ec2_create.ui.stub(:color)
      @knife_ec2_create.ui.should_receive(:info)           
    end

    context "for Linux" do
      before do
        @config = {:bootstrap_ip_address => "75.101.253.10"}
        @knife_ec2_create.config[:distro] = 'chef-full'
        @bootstrapper = Chef::Knife::Cloud::Bootstrapper.new(@config)
        @ssh_bootstrap_protocol = Chef::Knife::Cloud::SshBootstrapProtocol.new(@config)
        @unix_distribution = Chef::Knife::Cloud::UnixDistribution.new(@config)
        @ssh_bootstrap_protocol.stub(:send_bootstrap_command)
      end

      it "Creates an Ec2 instance and bootstraps it" do
        Chef::Knife::Cloud::Bootstrapper.should_receive(:new).with(@config).and_return(@bootstrapper)
        @bootstrapper.stub(:bootstrap).and_call_original
        @bootstrapper.should_receive(:create_bootstrap_protocol).and_return(@ssh_bootstrap_protocol)
        @bootstrapper.should_receive(:create_bootstrap_distribution).and_return(@unix_distribution)
        @knife_ec2_create.run
      end
    end

    context "for Windows" do
      before do
        @config = { :image_os_type => 'windows', :bootstrap_ip_address => "75.101.253.10", :bootstrap_protocol => 'winrm'}
        @knife_ec2_create.config[:image_os_type] = 'windows'
        @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
        @knife_ec2_create.config[:distro] = 'windows-chef-client-msi'
        @bootstrapper = Chef::Knife::Cloud::Bootstrapper.new(@config)
        @winrm_bootstrap_protocol = Chef::Knife::Cloud::WinrmBootstrapProtocol.new(@config)
        @windows_distribution = Chef::Knife::Cloud::WindowsDistribution.new(@config)
      end
      
      it "Creates an Ec2 instance for Windows and bootstraps it" do
        Chef::Knife::Cloud::Bootstrapper.should_receive(:new).with(@config).and_return(@bootstrapper)
        @bootstrapper.stub(:bootstrap).and_call_original
        @bootstrapper.should_receive(:create_bootstrap_protocol).and_return(@winrm_bootstrap_protocol)
        @bootstrapper.should_receive(:create_bootstrap_distribution).and_return(@windows_distribution)
        @winrm_bootstrap_protocol.stub(:send_bootstrap_command)
        @knife_ec2_create.run
      end
    end

  end
end
