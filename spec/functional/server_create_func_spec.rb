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
    allow(@ec2_service).to receive(:msg_pair)
    allow(@ec2_service).to receive(:print)
    allow(@knife_ec2_create).to receive(:create_service_instance).and_return(@ec2_service)
    allow(@knife_ec2_create).to receive(:puts)
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
                            :iam_instance_profile => 'profile',
                            :security_group_ids => [],
                            :private_dns_name => 'private_dns_name',
                            :placement_group => 'placement_group',
                            :root_device_type => 'root_device_type'
                          }

    @ec2_server_attribs.each_pair do |attrib, value|
      allow(@new_ec2_server).to receive(attrib).and_return(value)
    end
  end

  describe "run" do
    before(:each) do
      allow(@knife_ec2_create).to receive(:validate_params!)
      allow(@new_ec2_server).to receive(:wait_for)
      allow(@knife_ec2_create).to receive(:ami).and_return(double)
      allow(@knife_ec2_create.ami).to receive(:root_device_type)
      allow(@knife_ec2_create).to receive(:create_tags)
      allow(@knife_ec2_create).to receive(:service).and_return(double)
      expect(@knife_ec2_create.service).to receive(:ui=)
      expect(@knife_ec2_create.service).to receive(:is_image_windows?)
      @device_mapping = double
      allow(@device_mapping).to receive(:[]).with("volumeSize").and_return(0)
      allow(@knife_ec2_create.ami).to receive_message_chain(:block_device_mapping, :first).and_return(@device_mapping)
      expect(@knife_ec2_create.service).to receive(:create_server_dependencies)
      expect(@knife_ec2_create.service).to receive(:create_server).and_return(@new_ec2_server)
      allow(@knife_ec2_create.service).to receive(:server_summary)
      expect(@knife_ec2_create.service).to receive(:get_server_name)
      expect(@knife_ec2_create.service).to receive(:connection)
      allow(@knife_ec2_create).to receive(:ui).and_return(double)
      allow(@knife_ec2_create.ui).to receive(:color)
      expect(@knife_ec2_create.ui).to receive(:info)
      allow(@knife_ec2_create.service.connection).to receive(:connection).and_return(double)
      allow(@knife_ec2_create.service).to receive_message_chain(:addresses, :detect).and_return(double)
    end

    context "for Linux" do
      before do
        @config = {:bootstrap_ip_address => "75.101.253.10", :image_os_type => 'linux', :server_connect_attribute => :public_ip_address}
        @knife_ec2_create.config[:distro] = 'chef-full'
        @knife_ec2_create.config[:server_connect_attribute] = :public_ip_address
        @bootstrapper = Chef::Knife::Cloud::Bootstrapper.new(@config)
        @ssh_bootstrap_protocol = Chef::Knife::Cloud::SshBootstrapProtocol.new(@config)
        @unix_distribution = Chef::Knife::Cloud::UnixDistribution.new(@config)
        allow(@ssh_bootstrap_protocol).to receive(:send_bootstrap_command)
        expect(@knife_ec2_create.ami).to receive(:platform).and_return("linux")
      end

      it "Creates an Ec2 instance and bootstraps it" do
        expect(Chef::Knife::Cloud::Bootstrapper).to receive(:new).with(@config).and_return(@bootstrapper)
        allow(@bootstrapper).to receive(:bootstrap).and_call_original
        expect(@bootstrapper).to receive(:create_bootstrap_protocol).and_return(@ssh_bootstrap_protocol)
        expect(@bootstrapper).to receive(:create_bootstrap_distribution).and_return(@unix_distribution)
        @knife_ec2_create.run
      end
    end

    context "for Windows" do
      before do
        @config = { :image_os_type => 'windows', :bootstrap_ip_address => "75.101.253.10", :bootstrap_protocol => 'winrm', :server_connect_attribute => :public_ip_address}
        @knife_ec2_create.config[:image_os_type] = 'windows'
        @knife_ec2_create.config[:server_connect_attribute] = :public_ip_address
        @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
        @knife_ec2_create.config[:distro] = 'windows-chef-client-msi'
        @bootstrapper = Chef::Knife::Cloud::Bootstrapper.new(@config)
        @winrm_bootstrap_protocol = Chef::Knife::Cloud::WinrmBootstrapProtocol.new(@config)
        @windows_distribution = Chef::Knife::Cloud::WindowsDistribution.new(@config)
        expect(@knife_ec2_create.ami).to receive(:platform).and_return("windows")
      end

      it "Creates an Ec2 instance for Windows and bootstraps it" do
        expect(Chef::Knife::Cloud::Bootstrapper).to receive(:new).with(@config).and_return(@bootstrapper)
        allow(@bootstrapper).to receive(:bootstrap).and_call_original
        expect(@bootstrapper).to receive(:create_bootstrap_protocol).and_return(@winrm_bootstrap_protocol)
        expect(@bootstrapper).to receive(:create_bootstrap_distribution).and_return(@windows_distribution)
        allow(@winrm_bootstrap_protocol).to receive(:send_bootstrap_command)
        @knife_ec2_create.run
      end
    end
  end
end
