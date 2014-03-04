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
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/bootstrap_windows_ssh'

describe Chef::Knife::Ec2ServerCreate do
  before(:each) do
    @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
    @knife_ec2_create.initial_sleep_delay = 0
    @knife_ec2_create.stub(:tcp_test_ssh).and_return(true)

    {
      :image => 'image',
      :aws_ssh_key_id => 'aws_ssh_key_id',
      :aws_access_key_id => 'aws_access_key_id',
      :aws_secret_access_key => 'aws_secret_access_key'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @ec2_connection = double(Fog::Compute::AWS)
    @ec2_connection.stub_chain(:tags).and_return double('create', :create => true)
    @ec2_connection.stub_chain(:images, :get).and_return double('ami', :root_device_type => 'not_ebs', :platform => 'linux')
    @ec2_connection.stub_chain(:addresses).and_return [double('addesses', {
            :domain => 'standard',
            :public_ip => '111.111.111.111',
            :server_id => nil,
            :allocation_id => ''})]


    @ec2_servers = double()
    @new_ec2_server = double()

    @ec2_server_attribs = { :id => 'i-39382318',
                           :flavor_id => 'm1.small',
                           :image_id => 'ami-47241231',
                           :placement_group => 'some_placement_group',
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
      @new_ec2_server.stub(attrib).and_return(value)
    end
  end

  describe "run" do
    before do
      @ec2_servers.should_receive(:create).and_return(@new_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
      @ec2_connection.should_receive(:addresses)

      @eip = "111.111.111.111"
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)

      @knife_ec2_create.stub(:puts)
      @knife_ec2_create.stub(:print)
      @knife_ec2_create.config[:image] = '12345'

      @bootstrap = Chef::Knife::Bootstrap.new
      Chef::Knife::Bootstrap.stub(:new).and_return(@bootstrap)
      @bootstrap.should_receive(:run)
    end

    it "defaults to a distro of 'chef-full' for a linux instance" do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.config[:distro] = @knife_ec2_create.options[:distro][:default]
      @knife_ec2_create.run
      @bootstrap.config[:distro].should == 'chef-full'
    end

    it "creates an EC2 instance and bootstraps it" do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.should_receive(:ssh_override_winrm)
      @knife_ec2_create.run
      @knife_ec2_create.server.should_not == nil
    end

    it "set ssh_user value by using -x option for ssh bootstrap protocol or linux image" do
      # Currently -x option set config[:winrm_user]
      # default value of config[:ssh_user] is root
      @knife_ec2_create.config[:winrm_user] = "ubuntu"
      @knife_ec2_create.config[:ssh_user] = "root"

      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
      @knife_ec2_create.config[:ssh_user].should == "ubuntu"
      @knife_ec2_create.server.should_not == nil
    end

    it "set ssh_password value by using -P option for ssh bootstrap protocol or linux image" do
      # Currently -P option set config[:winrm_password]
      # default value of config[:ssh_password] is nil
      @knife_ec2_create.config[:winrm_password] = "winrm_password"
      @knife_ec2_create.config[:ssh_password] = nil

      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
      @knife_ec2_create.config[:ssh_password].should == "winrm_password"
      @knife_ec2_create.server.should_not == nil
    end

    it "set ssh_port value by using -p option for ssh bootstrap protocol or linux image" do
      # Currently -p option set config[:winrm_port]
      # default value of config[:ssh_port] is 22
      @knife_ec2_create.config[:winrm_port] = "1234"
      @knife_ec2_create.config[:ssh_port] = "22"

      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
      @knife_ec2_create.config[:ssh_port].should == "1234"
      @knife_ec2_create.server.should_not == nil
    end

    it "set identity_file value by using -i option for ssh bootstrap protocol or linux image" do
      # Currently -i option set config[:kerberos_keytab_file]
      # default value of config[:identity_file] is nil
      @knife_ec2_create.config[:kerberos_keytab_file] = "kerberos_keytab_file"
      @knife_ec2_create.config[:identity_file] = nil

      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
      @knife_ec2_create.config[:identity_file].should == "kerberos_keytab_file"
      @knife_ec2_create.server.should_not == nil
    end

    it "should never invoke windows bootstrap for linux instance" do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.should_not_receive(:bootstrap_for_windows_node)
      @knife_ec2_create.run
    end

    it "creates an EC2 instance, assigns existing EIP and bootstraps it" do
      @knife_ec2_create.config[:associate_eip] = @eip

      @new_ec2_server.stub(:public_ip_address).and_return(@eip)
      @ec2_connection.should_receive(:associate_address).with(@ec2_server_attribs[:id], @eip, nil, '')
      @new_ec2_server.should_receive(:wait_for).at_least(:twice).and_return(true)

      @knife_ec2_create.run
      @knife_ec2_create.server.should_not == nil
    end

    it "retries if it receives Fog::Compute::AWS::NotFound" do
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.should_receive(:create_tags).and_raise(Fog::Compute::AWS::NotFound)
      @knife_ec2_create.should_receive(:create_tags).and_return(true)
      @knife_ec2_create.should_receive(:sleep).and_return(true)
      @knife_ec2_create.ui.should_receive(:warn).with(/retrying/)
      @knife_ec2_create.run
    end
  end

  describe "run for EC2 Windows instance" do
    before do
      @ec2_servers.should_receive(:create).and_return(@new_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
      @ec2_connection.should_receive(:addresses)

      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)

      @knife_ec2_create.stub(:puts)
      @knife_ec2_create.stub(:print)
      @knife_ec2_create.config[:identity_file] = "~/.ssh/aws-key.pem"
      @knife_ec2_create.config[:image] = '12345'
      @knife_ec2_create.stub(:is_image_windows?).and_return(true)
      @knife_ec2_create.stub(:tcp_test_winrm).and_return(true)
    end

    it "bootstraps via the WinRM protocol" do
      @knife_ec2_create.config[:winrm_password] = 'winrm-password'
      @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap_winrm)
      @bootstrap_winrm.should_receive(:run)
      @knife_ec2_create.should_not_receive(:ssh_override_winrm)
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
    end

    it "set default distro to windows-chef-client-msi for windows" do
      @knife_ec2_create.config[:winrm_password] = 'winrm-password'
      @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'      
      @bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(@bootstrap_winrm)
      @bootstrap_winrm.should_receive(:run)
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
      @knife_ec2_create.config[:distro].should == "windows-chef-client-msi"
    end

    it "bootstraps via the SSH protocol" do
      @knife_ec2_create.config[:bootstrap_protocol] = 'ssh'
      bootstrap_win_ssh = Chef::Knife::BootstrapWindowsSsh.new
      Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(bootstrap_win_ssh)
      bootstrap_win_ssh.should_receive(:run)
      @knife_ec2_create.should_receive(:ssh_override_winrm)
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
    end

    it "should use configured SSH port" do
      @knife_ec2_create.config[:bootstrap_protocol] = 'ssh'
      @knife_ec2_create.config[:ssh_port] = 422

      @knife_ec2_create.should_receive(:tcp_test_ssh).with('ec2-75.101.253.10.compute-1.amazonaws.com', 422).and_return(true)

      bootstrap_win_ssh = Chef::Knife::BootstrapWindowsSsh.new
      Chef::Knife::BootstrapWindowsSsh.stub(:new).and_return(bootstrap_win_ssh)
      bootstrap_win_ssh.should_receive(:run)
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.run
    end

    it "should never invoke linux bootstrap" do
      @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @knife_ec2_create.stub(:windows_password).and_return("")
      @knife_ec2_create.should_not_receive(:bootstrap_for_linux_node)
      @new_ec2_server.should_receive(:wait_for).and_return(true)
      @knife_ec2_create.stub(:bootstrap_for_windows_node).and_return double("bootstrap", :run => true)
      @knife_ec2_create.run
    end

    it "waits for EC2 to generate password if not supplied" do
      @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @knife_ec2_create.config[:winrm_password] = nil
      @knife_ec2_create.should_receive(:windows_password).and_return("")
      @new_ec2_server.stub(:wait_for).and_return(true)
      @knife_ec2_create.stub(:check_windows_password_available).and_return(true)
      bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      Chef::Knife::BootstrapWindowsWinrm.stub(:new).and_return(bootstrap_winrm)
      bootstrap_winrm.should_receive(:run)
      @knife_ec2_create.run
    end
  end

  describe "when setting tags" do
    before do
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
      @knife_ec2_create.stub(:bootstrap_for_linux_node).and_return double("bootstrap", :run => true)
      @ec2_connection.stub(:servers).and_return(@ec2_servers)
      @ec2_connection.should_receive(:addresses)
      @new_ec2_server.stub(:wait_for).and_return(true)
      @ec2_servers.stub(:create).and_return(@new_ec2_server)
      @knife_ec2_create.stub(:puts)
      @knife_ec2_create.stub(:print)
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

  # This shared examples group can be used to house specifications that
  # are common to both the Linux and Windows bootstraping process. This
  # would remove a lot of testing duplication that is currently present.
  shared_examples "generic bootstrap configurations" do
    context "data bag secret" do
      before(:each) do
        Chef::Config[:knife][:secret] = "sys-knife-secret"
      end

     it "uses the the knife configuration when no explicit value is provided" do
        expect(bootstrap.config[:secret]).to eql("sys-knife-secret")
      end

      it "prefers using a provided value instead of the knife confiuration" do
        subject.config[:secret] = "cli-provided-secret"
        expect(bootstrap.config[:secret]).to eql("cli-provided-secret")
      end
    end

    context "data bag secret file" do
      before(:each) do
        Chef::Config[:knife][:secret_file] = "sys-knife-secret-file"
      end

      it "uses the the knife configuration when no explicit value is provided" do
        expect(bootstrap.config[:secret_file]).to eql("sys-knife-secret-file")
      end

      it "prefers using a provided value instead of the knife confiuration" do
        subject.config[:secret_file] = "cli-provided-secret-file"
        expect(bootstrap.config[:secret_file]).to eql("cli-provided-secret-file")
      end
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

      @bootstrap = @knife_ec2_create.bootstrap_for_linux_node(@new_ec2_server, @new_ec2_server.dns_name)
    end

    include_examples "generic bootstrap configurations" do
      subject { @knife_ec2_create }
      let(:bootstrap) { @knife_ec2_create.bootstrap_for_linux_node(@new_ec2_server, @new_ec2_server.dns_name) }
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

      bootstrap = @knife_ec2_create.bootstrap_for_linux_node(@new_ec2_server, @new_ec2_server.dns_name)
      bootstrap.config[:chef_node_name].should == @new_ec2_server.id
    end

    it "configures the bootstrap to use prerelease versions of chef if specified" do
      @bootstrap.config[:prerelease].should be_false

      @knife_ec2_create.config[:prerelease] = true

      bootstrap = @knife_ec2_create.bootstrap_for_linux_node(@new_ec2_server, @new_ec2_server.dns_name)
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
  describe "when configuring the winrm bootstrap process for windows" do
    before do
      @knife_ec2_create.stub(:fetch_server_fqdn).and_return("SERVERNAME")
      @knife_ec2_create.config[:winrm_user] = "Administrator"
      @knife_ec2_create.config[:winrm_password] = "password"
      @knife_ec2_create.config[:winrm_port] = 12345
      @knife_ec2_create.config[:winrm_transport] = 'ssl'
      @knife_ec2_create.config[:kerberos_realm] = "realm"
      @knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @knife_ec2_create.config[:kerberos_service] = "service"
      @knife_ec2_create.config[:chef_node_name] = "blarf"
      @knife_ec2_create.config[:template_file] = '~/.chef/templates/my-bootstrap.sh.erb'
      @knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'
      @knife_ec2_create.config[:run_list] = ['role[base]']
      @knife_ec2_create.config[:json_attributes] = "{'my_attributes':{'foo':'bar'}"
      @bootstrap = @knife_ec2_create.bootstrap_for_windows_node(@new_ec2_server, @new_ec2_server.dns_name)
   end

    include_examples "generic bootstrap configurations" do
      subject { @knife_ec2_create }
      let(:bootstrap) { @knife_ec2_create.bootstrap_for_linux_node(@new_ec2_server, @new_ec2_server.dns_name) }
    end

    it "should set the winrm username correctly" do
      @bootstrap.config[:winrm_user].should == @knife_ec2_create.config[:winrm_user]
    end
    it "should set the winrm password correctly" do
      @bootstrap.config[:winrm_password].should == @knife_ec2_create.config[:winrm_password]
    end

    it "should set the winrm port correctly" do
      @bootstrap.config[:winrm_port].should == @knife_ec2_create.config[:winrm_port]
    end

    it "should set the winrm transport layer correctly" do
      @bootstrap.config[:winrm_transport].should == @knife_ec2_create.config[:winrm_transport]
    end

    it "should set the kerberos realm correctly" do
      @bootstrap.config[:kerberos_realm].should == @knife_ec2_create.config[:kerberos_realm]
    end

    it "should set the kerberos service correctly" do
      @bootstrap.config[:kerberos_service].should == @knife_ec2_create.config[:kerberos_service]
    end

    it "should set the bootstrap 'name argument' to the Windows/AD hostname of the EC2 server" do
      @bootstrap.name_args.should == ["SERVERNAME"]
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server when AD/Kerberos is not used" do
      @knife_ec2_create.config[:kerberos_realm] = nil
      @bootstrap = @knife_ec2_create.bootstrap_for_windows_node(@new_ec2_server, @new_ec2_server.dns_name)
      @bootstrap.name_args.should == ['ec2-75.101.253.10.compute-1.amazonaws.com']
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      @bootstrap.config[:first_boot_attributes].should == "{'my_attributes':{'foo':'bar'}"
    end

    it "configures sets the bootstrap's run_list" do
      @bootstrap.config[:run_list].should == ['role[base]']
    end
 end

  describe "when validating the command-line parameters" do
    before do
      Fog::Compute::AWS.stub(:new).and_return(@ec2_connection)
      @knife_ec2_create.ui.stub(:error)
    end

    describe "when reading aws_credential_file" do 
      before do
        Chef::Config[:knife].delete(:aws_access_key_id)
        Chef::Config[:knife].delete(:aws_secret_access_key)

        Chef::Config[:knife][:aws_credential_file] = '/apple/pear'
        @access_key_id = 'access_key_id'
        @secret_key = 'secret_key'
      end

      it "reads UNIX Line endings" do
        File.stub(:read).
          and_return("AWSAccessKeyId=#{@access_key_id}\nAWSSecretKey=#{@secret_key}")
        @knife_ec2_create.validate!
        Chef::Config[:knife][:aws_access_key_id].should == @access_key_id
        Chef::Config[:knife][:aws_secret_access_key].should == @secret_key
      end

      it "reads DOS Line endings" do
        File.stub(:read).
          and_return("AWSAccessKeyId=#{@access_key_id}\r\nAWSSecretKey=#{@secret_key}")
        @knife_ec2_create.validate!
        Chef::Config[:knife][:aws_access_key_id].should == @access_key_id
        Chef::Config[:knife][:aws_secret_access_key].should == @secret_key
      end
    end

    it "disallows security group names when using a VPC" do
      @knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      @knife_ec2_create.config[:security_group_ids] = 'sg-aabbccdd'
      @knife_ec2_create.config[:security_groups] = 'groupname'

      lambda { @knife_ec2_create.validate! }.should raise_error SystemExit
    end

    it "disallows private ips when not using a VPC" do
      @knife_ec2_create.config[:private_ip_address] = '10.0.0.10'

      lambda { @knife_ec2_create.validate! }.should raise_error SystemExit
    end

    it "disallows specifying credentials file and aws keys" do
      Chef::Config[:knife][:aws_credential_file] = '/apple/pear'
      File.stub(:read).and_return("AWSAccessKeyId=b\nAWSSecretKey=a")

      lambda { @knife_ec2_create.validate! }.should raise_error SystemExit
    end

    it "disallows associate public ip option when not using a VPC" do
      @knife_ec2_create.config[:associate_public_ip] = true
      @knife_ec2_create.config[:subnet_id] = nil

      lambda { @knife_ec2_create.validate! }.should raise_error SystemExit
    end
  end

  describe "when creating the server definition" do
    before do
      Fog::Compute::AWS.stub(:new).and_return(@ec2_connection)
    end

    it "sets the specified placement_group" do
      @knife_ec2_create.config[:placement_group] = ['some_placement_group']
      server_def = @knife_ec2_create.create_server_def

      server_def[:placement_group].should == ['some_placement_group']
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

    it "sets the specified private ip address" do
      @knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      @knife_ec2_create.config[:private_ip_address] = '10.0.0.10'
      server_def = @knife_ec2_create.create_server_def

      server_def[:subnet_id].should == 'subnet-1a2b3c4d'
      server_def[:private_ip_address].should == '10.0.0.10'
    end

    it "sets the IAM server role when one is specified" do
      @knife_ec2_create.config[:iam_instance_profile] = ['iam-role']
      server_def = @knife_ec2_create.create_server_def

      server_def[:iam_instance_profile_name].should == ['iam-role']
    end

    it "doesn't set an IAM server role by default" do
      server_def = @knife_ec2_create.create_server_def

      server_def[:iam_instance_profile_name].should == nil
    end
    
    it 'Set Tenancy Dedicated when both VPC mode and Flag is True' do
      @knife_ec2_create.config[:dedicated_instance] = true
      @knife_ec2_create.stub(:vpc_mode? => true)
      
      server_def = @knife_ec2_create.create_server_def
      server_def[:tenancy].should == "dedicated"
    end
    
    it 'Tenancy should be default with no vpc mode even is specified' do
      @knife_ec2_create.config[:dedicated_instance] = true
      
      server_def = @knife_ec2_create.create_server_def
      server_def[:tenancy].should == nil
    end
    
    it 'Tenancy should be default with vpc but not requested' do
      @knife_ec2_create.stub(:vpc_mode? => true)
      
      server_def = @knife_ec2_create.create_server_def
      server_def[:tenancy].should == nil
    end
    
    it "sets associate_public_ip to true if specified and in vpc_mode" do
      @knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      @knife_ec2_create.config[:associate_public_ip] = true
      server_def = @knife_ec2_create.create_server_def

      server_def[:subnet_id].should == 'subnet-1a2b3c4d'
      server_def[:associate_public_ip].should == true
    end
  end

  describe "ssh_connect_host" do
    before(:each) do
      @new_ec2_server.stub(
        :dns_name => 'public_name',
        :private_ip_address => 'private_ip',
        :custom => 'custom'
      )
      @knife_ec2_create.stub(:server => @new_ec2_server)
    end

    describe "by default" do
      it 'should use public dns name' do
        @knife_ec2_create.ssh_connect_host.should == 'public_name'
      end
    end

    describe "with vpc_mode?" do
      it 'should use private ip' do
        @knife_ec2_create.stub(:vpc_mode? => true)
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

  describe "tcp_test_ssh" do
    # Normally we would only get the header after we send a client header, e.g. 'SSH-2.0-client'
    it "should return true if we get an ssh header" do
      @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      TCPSocket.stub(:new).and_return(StringIO.new("SSH-2.0-OpenSSH_6.1p1 Debian-4"))
      IO.stub(:select).and_return(true)
      @knife_ec2_create.should_receive(:tcp_test_ssh).and_yield.and_return(true)
      @knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22) {nil}
    end

    it "should return false if we do not get an ssh header" do
      @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      TCPSocket.stub(:new).and_return(StringIO.new(""))
      IO.stub(:select).and_return(true)
      @knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22).should be_false
    end

    it "should return false if the socket isn't ready" do
      @knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      TCPSocket.stub(:new)
      IO.stub(:select).and_return(false)
      @knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22).should be_false
    end
  end
end
