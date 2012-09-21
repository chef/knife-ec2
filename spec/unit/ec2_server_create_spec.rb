#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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
#

require File.expand_path('../../spec_helper', __FILE__)
require 'fog'
require 'chef/knife/bootstrap'

describe Chef::Knife::Ec2ServerCreate do
  before do
    @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
    @knife_ec2_create.initial_sleep_delay = 0
    @knife_ec2_create.stub!(:tcp_test_ssh).and_return(true)

    {
      :image => 'image',
      :aws_ssh_key_id => 'aws_ssh_key_id',
      :aws_access_key_id => 'aws_access_key_id',
      :aws_secret_access_key => 'aws_secret_access_key'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @ec2_connection = mock(Fog::Compute::AWS)
    @ec2_connection.stub_chain(:tags).and_return mock('create', :create => true)
    @ec2_connection.stub_chain(:images, :get).and_return mock('ami', :root_device_type => 'not_ebs',
                                                              :platform => "linux")
    @ec2_servers = mock()
    @new_ec2_server = mock()

    @ec2_server_attribs = { :id => 'i-39382318',
                           :flavor_id => 'm1.small',
                           :image_id => 'ami-47241231',
                           :availability_zone => 'us-west-1',
                           :key_name => 'my_ssh_key',
                           :groups => ['group1', 'group2'],
                           :security_group_ids => ['sg-00aa11bb'],
                           :dns_name => 'ec2-75.101.253.10.compute-1.amazonaws.com',
                           :public_ip_address => '75.101.253.10',
                           :private_dns_name => 'ip-10-251-75-20.ec2.internal',
                           :private_ip_address => '10.251.75.20',
                           :root_device_type => 'not_ebs' }

    @ec2_server_attribs.each_pair do |attrib, value|
      @new_ec2_server.stub!(attrib).and_return(value)
    end
  end

  describe "run" do
    it "creates an EC2 instance and bootstraps it" do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @ec2_servers.should_receive(:create).and_return(@new_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)

      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)

      @knife_ec2_create.stub!(:puts)
      @knife_ec2_create.stub!(:print)
      @knife_ec2_create.config[:image] = '12345'


      @bootstrap = Chef::Knife::Bootstrap.new
      Chef::Knife::Bootstrap.stub!(:new).and_return(@bootstrap)
      @bootstrap.should_receive(:run)
      @knife_ec2_create.run
      @knife_ec2_create.server.should_not == nil
    end
  end
  describe "when setting tags" do
    before do
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
      @knife_ec2_create.stub!(:bootstrap_for_node).and_return mock("bootstrap", :run => true)
      @ec2_connection.stub!(:servers).and_return(@ec2_servers)
      @new_ec2_server.stub!(:wait_for).and_return(true)
      @ec2_servers.stub!(:create).and_return(@new_ec2_server)
      @knife_ec2_create.stub!(:puts)
      @knife_ec2_create.stub!(:print)
    end

    it "sets the Name tag to the instance id by default" do
      @ec2_connection.tags.should_receive(:create).with(:key => "Name",
                                                        :value => @new_ec2_server.id,
                                                        :resource_id => @new_ec2_server.id)
      @knife_ec2_create.run
    end

    it "sets the Name tag to the chef_node_name when given" do
      @knife_ec2_create.config[:chef_node_name] = "wombat"
      @ec2_connection.tags.should_receive(:create).with(:key => "Name",
                                                        :value => "wombat",
                                                        :resource_id => @new_ec2_server.id)
      @knife_ec2_create.run
    end

    it "sets the Name tag to the specified name when given --tags Name=NAME" do
      @knife_ec2_create.config[:tags] = ["Name=bobcat"]
      @ec2_connection.tags.should_receive(:create).with(:key => "Name",
                                                        :value => "bobcat",
                                                        :resource_id => @new_ec2_server.id)
      @knife_ec2_create.run
    end

    it "sets arbitrary tags" do
      @knife_ec2_create.config[:tags] = ["foo=bar"]
      @ec2_connection.tags.should_receive(:create).with(:key => "foo",
                                                        :value => "bar",
                                                        :resource_id => @new_ec2_server.id)
      @knife_ec2_create.run
    end

  end

  describe "when configuring the bootstrap process" do
    before do
      @knife_ec2_create.config[:ssh_user] = "ubuntu"
      @knife_ec2_create.config[:identity_file] = "~/.ssh/aws-key.pem"
      @knife_ec2_create.config[:ssh_port] = 22
      @knife_ec2_create.config[:ssh_gateway] = 'bastion.host.com'
      @knife_ec2_create.config[:chef_node_name] = "blarf"
      @knife_ec2_create.config[:template_file] = '~/.chef/templates/my-bootstrap.sh.erb'
      @knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'
      @knife_ec2_create.config[:run_list] = ['role[base]']
      @knife_ec2_create.config[:json_attributes] = "{'my_attributes':{'foo':'bar'}"

      @bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server, @new_ec2_server.dns_name)
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server" do
      @bootstrap.name_args.should == ['ec2-75.101.253.10.compute-1.amazonaws.com']
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      @bootstrap.config[:first_boot_attributes].should == "{'my_attributes':{'foo':'bar'}"
    end

    it "configures sets the bootstrap's run_list" do
      @bootstrap.config[:run_list].should == ['role[base]']
    end

    it "configures the bootstrap to use the correct ssh_user login" do
      @bootstrap.config[:ssh_user].should == 'ubuntu'
    end

    it "configures the bootstrap to use the correct ssh_gateway host" do
      @bootstrap.config[:ssh_gateway].should == 'bastion.host.com'
    end

    it "configures the bootstrap to use the correct ssh identity file" do
      @bootstrap.config[:identity_file].should == "~/.ssh/aws-key.pem"
    end

    it "configures the bootstrap to use the correct ssh_port number" do
      @bootstrap.config[:ssh_port].should == 22
    end

    it "configures the bootstrap to use the configured node name if provided" do
      @bootstrap.config[:chef_node_name].should == 'blarf'
    end

    it "configures the bootstrap to use the EC2 server id if no explicit node name is set" do
      @knife_ec2_create.config[:chef_node_name] = nil

      bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server, @new_ec2_server.dns_name)
      bootstrap.config[:chef_node_name].should == @new_ec2_server.id
    end

    it "configures the bootstrap to use prerelease versions of chef if specified" do
      @bootstrap.config[:prerelease].should be_false

      @knife_ec2_create.config[:prerelease] = true

      bootstrap = @knife_ec2_create.bootstrap_for_node(@new_ec2_server, @new_ec2_server.dns_name)
      bootstrap.config[:prerelease].should be_true
    end

    it "configures the bootstrap to use the desired distro-specific bootstrap script" do
      @bootstrap.config[:distro].should == 'ubuntu-10.04-magic-sparkles'
    end

    it "configures the bootstrap to use sudo" do
      @bootstrap.config[:use_sudo].should be_true
    end

    it "configured the bootstrap to use the desired template" do
      @bootstrap.config[:template_file].should == '~/.chef/templates/my-bootstrap.sh.erb'
    end

    it "configured the bootstrap to set an ec2 hint (via Chef::Config)" do
      Chef::Config[:knife][:hints]["ec2"].should_not be_nil
    end
  end

  describe "when validating the command-line parameters" do
    before do
      Fog::Compute::AWS.stub(:new).and_return(@ec2_connection)
      @knife_ec2_create.ui.stub!(:error)
    end

    it "disallows security group names when using a VPC" do
      @knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      @knife_ec2_create.config[:security_group_ids] = 'sg-aabbccdd'
      @knife_ec2_create.config[:security_groups] = 'groupname'

      lambda { @knife_ec2_create.validate! }.should raise_error SystemExit
    end
  end

  describe "when creating the server definition" do
    before do
      Fog::Compute::AWS.stub(:new).and_return(@ec2_connection)
    end

    it "sets the specified security group names" do
      @knife_ec2_create.config[:security_groups] = ['groupname']
      server_def = @knife_ec2_create.create_server_def

      server_def[:groups].should == ['groupname']
    end

    it "sets the specified security group ids" do
      @knife_ec2_create.config[:security_group_ids] = ['sg-aabbccdd']
      server_def = @knife_ec2_create.create_server_def

      server_def[:security_group_ids].should == ['sg-aabbccdd']
    end

    it "sets the image id from CLI arguments over knife config" do
      @knife_ec2_create.config[:image] = "ami-aaa"
      Chef::Config[:knife][:image] = "ami-zzz"
      server_def = @knife_ec2_create.create_server_def

      server_def[:image_id].should == "ami-aaa"
    end

    it "sets the flavor id from CLI arguments over knife config" do
      @knife_ec2_create.config[:flavor] = "massive"
      Chef::Config[:knife][:flavor] = "bitty"
      server_def = @knife_ec2_create.create_server_def

      server_def[:flavor_id].should == "massive"
    end

    it "sets the availability zone from CLI arguments over knife config" do
      @knife_ec2_create.config[:availability_zone] = "dis-one"
      Chef::Config[:knife][:availability_zone] = "dat-one"
      server_def = @knife_ec2_create.create_server_def

      server_def[:availability_zone].should == "dis-one"
    end

    it "adds the specified ephemeral device mappings" do
      @knife_ec2_create.config[:ephemeral] = [ "/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde" ]
      server_def = @knife_ec2_create.create_server_def

      server_def[:block_device_mapping].should == [{ "VirtualName" => "ephemeral0", "DeviceName" => "/dev/sdb" },
                                                   { "VirtualName" => "ephemeral1", "DeviceName" => "/dev/sdc" },
                                                   { "VirtualName" => "ephemeral2", "DeviceName" => "/dev/sdd" },
                                                   { "VirtualName" => "ephemeral3", "DeviceName" => "/dev/sde" }]
    end
  end

  describe "ssh_connect_host" do
    before(:each) do
      @new_ec2_server.stub!(
        :dns_name => 'public_name',
        :private_ip_address => 'private_ip',
        :custom => 'custom'
      )
      @knife_ec2_create.stub!(:server => @new_ec2_server)
    end

    describe "by default" do
      it 'should use public dns name' do
        @knife_ec2_create.ssh_connect_host.should == 'public_name'
      end
    end

    describe "with vpc_mode?" do
      it 'should use private ip' do
        @knife_ec2_create.stub!(:vpc_mode? => true)
        @knife_ec2_create.ssh_connect_host.should == 'private_ip'
      end

    end

    describe "with custom server attribute" do
      it 'should use custom server attribute' do
        @knife_ec2_create.config[:server_connect_attribute] = 'custom'
        @knife_ec2_create.ssh_connect_host.should == 'custom'
      end
    end
  end
end
