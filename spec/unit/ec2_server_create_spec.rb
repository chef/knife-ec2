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
require 'net/ssh/proxy/http'
require 'net/ssh/proxy/command'
require 'net/ssh/gateway'
require 'fog/aws'
require 'chef/knife/bootstrap'
require 'chef/knife/bootstrap_windows_winrm'
require 'chef/knife/bootstrap_windows_ssh'

describe Chef::Knife::Ec2ServerCreate do
  let(:knife_ec2_create) { Chef::Knife::Ec2ServerCreate.new }
  let(:ec2_connection) { double(Fog::Compute::AWS) }
  let(:ec2_servers) { double() }

  let(:new_ec2_server) { double }
  let(:spot_requests) { double }
  let(:new_spot_request) { double }

  let(:ec2_server_attribs) { { :id => 'i-39382318',
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
                           :root_device_type => 'not_ebs' } }

  let(:spot_request_attribs) { { :id => 'test_spot_request_id',
                           :price => 0.001,
                           :request_type => 'persistent',
                           :created_at => '2015-07-14 09:53:11 UTC',
                           :instance_count => nil,
                           :instance_id => 'test_spot_instance_id',
                           :state => 'open',
                           :key_name => 'ssh_key_name',
                           :availability_zone => nil,
                           :flavor_id => 'm1.small',
                           :image_id => 'image' } }

  let(:my_vpc) { 'vpc-12345678' }

  before(:each) do
    knife_ec2_create.initial_sleep_delay = 0
    allow(knife_ec2_create).to receive(:tcp_test_ssh).and_return(true)

    {
      :image => 'image',
      :ssh_key_name => 'ssh_key_name',
      :aws_access_key_id => 'aws_access_key_id',
      :aws_secret_access_key => 'aws_secret_access_key',
      :network_interfaces => ['eni-12345678',
                              'eni-87654321']
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    allow(ec2_connection).to receive(:tags).and_return double('create', :create => true)
    allow(ec2_connection).to receive_message_chain(:images, :get).and_return double('ami', :root_device_type => 'not_ebs', :platform => 'linux')
    allow(ec2_connection).to receive(:addresses).and_return [double('addesses', {
            :domain => 'standard',
            :public_ip => '111.111.111.111',
            :server_id => nil,
            :allocation_id => ''})]

    allow(ec2_connection).to receive(:subnets).and_return [@subnet_1, @subnet_2]
    allow(ec2_connection).to receive_message_chain(:network_interfaces, :all).and_return [
      double('network_interfaces', network_interface_id: 'eni-12345678'),
      double('network_interfaces', network_interface_id: 'eni-87654321')
    ]

    ec2_server_attribs.each_pair do |attrib, value|
      allow(new_ec2_server).to receive(attrib).and_return(value)
    end

    spot_request_attribs.each_pair do |attrib, value|
      allow(new_spot_request).to receive(attrib).and_return(value)
    end

    @bootstrap = Chef::Knife::Bootstrap.new
    allow(Chef::Knife::Bootstrap).to receive(:new).and_return(@bootstrap)

    @validation_key_url = 's3://bucket/foo/bar'
    @validation_key_file = '/tmp/a_good_temp_file'
    @validation_key_body = "TEST VALIDATION KEY\n"
    @vpc_id = "vpc-1a2b3c4d"
    @vpc_security_group_ids = ["sg-1a2b3c4d"]
  end

  describe "Spot Instance creation" do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      knife_ec2_create.config[:spot_price] = 0.001
      knife_ec2_create.config[:spot_request_type] = 'persistent'
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:msg_pair)
      allow(knife_ec2_create.ui).to receive(:color).and_return('')
      allow(knife_ec2_create).to receive(:confirm)
      @spot_instance_server_def = {
          :image_id => "image",
          :groups => nil,
          :flavor_id => nil,
          :key_name => "ssh_key_name",
          :availability_zone => nil,
          :security_group_ids => nil,
          :price => 0.001,
          :request_type => 'persistent',
          :placement_group => nil,
          :iam_instance_profile_name => nil,
          :ebs_optimized => "false"
        }
      allow(@bootstrap).to receive(:run)
    end

    it "creates a new spot instance request with request type as persistent" do
      expect(ec2_connection).to receive(
        :spot_requests).and_return(spot_requests)
      expect(spot_requests).to receive(
        :create).with(@spot_instance_server_def).and_return(new_spot_request)
      knife_ec2_create.config[:yes] = true
      allow(new_spot_request).to receive(:wait_for).and_return(true)
      allow(ec2_connection).to receive(:servers).and_return(ec2_servers)
      allow(ec2_servers).to receive(
        :get).with(new_spot_request.instance_id).and_return(new_ec2_server)
      allow(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
      expect(new_spot_request.request_type).to eq('persistent')
    end

    it "successfully creates a new spot instance" do
      allow(ec2_connection).to receive(
        :spot_requests).and_return(spot_requests)
      allow(spot_requests).to receive(
        :create).with(@spot_instance_server_def).and_return(new_spot_request)
      knife_ec2_create.config[:yes] = true
      expect(new_spot_request).to receive(:wait_for).and_return(true)
      expect(ec2_connection).to receive(:servers).and_return(ec2_servers)
      expect(ec2_servers).to receive(
        :get).with(new_spot_request.instance_id).and_return(new_ec2_server)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
    end

    it "does not create the spot instance request and creates a regular instance" do
      knife_ec2_create.config.delete(:spot_price)
      expect(ec2_connection).to receive(:servers).and_return(ec2_servers)
      expect(ec2_servers).to receive(
        :create).and_return(new_ec2_server)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
    end

    context 'spot-wait-mode option' do
      context 'when spot-price is not given' do
        context 'spot-wait-mode option is not given' do
          before do
            knife_ec2_create.config.delete(:spot_price)
          end

          it 'does not raise error' do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              'spot-wait-mode option requires that a spot-price option is set.'
            )
            expect { knife_ec2_create.validate! }.to_not raise_error
          end
        end

        context 'spot-wait-mode option is given' do
          before do
            knife_ec2_create.config.delete(:spot_price)
            knife_ec2_create.config[:spot_wait_mode] = 'wait'
          end

          it 'raises error' do
            expect(knife_ec2_create.ui).to receive(:error).with(
              'spot-wait-mode option requires that a spot-price option is set.'
            )
            expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
          end
        end
      end

      context 'when spot-price is given' do
        context 'spot-wait-mode option is not given' do
          before do
            knife_ec2_create.config[:spot_price] = 0.001
          end

          it 'does not raise error' do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              'spot-wait-mode option requires that a spot-price option is set.'
            )
            expect { knife_ec2_create.validate! }.to_not raise_error
          end
        end

        context 'spot-wait-mode option is given' do
          before do
            knife_ec2_create.config[:spot_price] = 0.001
            knife_ec2_create.config[:spot_wait_mode] = 'exit'
          end

          it 'does not raise error' do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              'spot-wait-mode option requires that a spot-price option is set.'
            )
            expect { knife_ec2_create.validate! }.to_not raise_error
          end
        end
      end
    end
  end

  describe "run" do
    before do
      expect(ec2_servers).to receive(:create).and_return(new_ec2_server)
      expect(ec2_connection).to receive(:servers).and_return(ec2_servers)
      expect(ec2_connection).to receive(:addresses)

      @eip = "111.111.111.111"
      expect(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)

      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
      knife_ec2_create.config[:image] = '12345'
      expect(@bootstrap).to receive(:run)
    end

    it "defaults to a distro of 'chef-full' for a linux instance" do
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.config[:distro] = knife_ec2_create.options[:distro][:default]
      expect(knife_ec2_create).to receive(:default_bootstrap_template).and_return('chef-full')
      knife_ec2_create.run
    end

    it "creates an EC2 instance and bootstraps it" do
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      expect(knife_ec2_create).to receive(:ssh_override_winrm)
      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "set ssh_user value by using -x option for ssh bootstrap protocol or linux image" do
      # Currently -x option set config[:winrm_user]
      # default value of config[:ssh_user] is root
      knife_ec2_create.config[:winrm_user] = "ubuntu"
      knife_ec2_create.config[:ssh_user] = "root"

      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
      expect(knife_ec2_create.config[:ssh_user]).to eq("ubuntu")
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "set ssh_password value by using -P option for ssh bootstrap protocol or linux image" do
      # Currently -P option set config[:winrm_password]
      # default value of config[:ssh_password] is nil
      knife_ec2_create.config[:winrm_password] = "winrm_password"
      knife_ec2_create.config[:ssh_password] = nil

      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
      expect(knife_ec2_create.config[:ssh_password]).to eq("winrm_password")
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "set ssh_port value by using -p option for ssh bootstrap protocol or linux image" do
      # Currently -p option set config[:winrm_port]
      # default value of config[:ssh_port] is 22
      knife_ec2_create.config[:winrm_port] = "1234"
      knife_ec2_create.config[:ssh_port] = "22"

      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
      expect(knife_ec2_create.config[:ssh_port]).to eq("1234")
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "set identity_file value by using -i option for ssh bootstrap protocol or linux image" do
      # Currently -i option set config[:kerberos_keytab_file]
      # default value of config[:identity_file] is nil
      knife_ec2_create.config[:kerberos_keytab_file] = "kerberos_keytab_file"
      knife_ec2_create.config[:identity_file] = nil

      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
      expect(knife_ec2_create.config[:identity_file]).to eq("kerberos_keytab_file")
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "should never invoke windows bootstrap for linux instance" do
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      expect(knife_ec2_create).not_to receive(:bootstrap_for_windows_node)
      knife_ec2_create.run
    end

    it "creates an EC2 instance, assigns existing EIP and bootstraps it" do
      knife_ec2_create.config[:associate_eip] = @eip

      allow(new_ec2_server).to receive(:public_ip_address).and_return(@eip)
      expect(ec2_connection).to receive(:associate_address).with(ec2_server_attribs[:id], @eip, nil, '')
      expect(new_ec2_server).to receive(:wait_for).at_least(:twice).and_return(true)

      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "creates an EC2 instance, enables ClassicLink and bootstraps it" do
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = @vpc_security_group_ids

      expect(ec2_connection).to receive(:attach_classic_link_vpc).with(ec2_server_attribs[:id], @vpc_id, @vpc_security_group_ids)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)

      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "retries if it receives Fog::Compute::AWS::NotFound" do
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      expect(knife_ec2_create).to receive(:create_tags).and_raise(Fog::Compute::AWS::NotFound)
      expect(knife_ec2_create).to receive(:create_tags).and_return(true)
      expect(knife_ec2_create).to receive(:sleep).and_return(true)
      expect(knife_ec2_create.ui).to receive(:warn).with(/retrying/)
      knife_ec2_create.run
    end

    it 'actually writes to the validation key tempfile' do
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      Chef::Config[:knife][:validation_key_url] = @validation_key_url
      knife_ec2_create.config[:validation_key_url] = @validation_key_url

      allow(knife_ec2_create).to receive_message_chain(:validation_key_tmpfile, :path).and_return(@validation_key_file)
      allow(Chef::Knife::S3Source).to receive(:fetch).with(@validation_key_url).and_return(@validation_key_body)
      expect(File).to receive(:open).with(@validation_key_file, 'w')
      knife_ec2_create.run
    end
  end

  describe "run for EC2 Windows instance" do
    before do
      expect(ec2_servers).to receive(:create).and_return(new_ec2_server)
      expect(ec2_connection).to receive(:servers).and_return(ec2_servers)
      expect(ec2_connection).to receive(:addresses)

      expect(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)

      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
      knife_ec2_create.config[:identity_file] = "~/.ssh/aws-key.pem"
      knife_ec2_create.config[:image] = '12345'
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(true)
      allow(knife_ec2_create).to receive(:tcp_test_winrm).and_return(true)
    end

    it "bootstraps via the WinRM protocol" do
      knife_ec2_create.config[:winrm_password] = 'winrm-password'
      knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      allow(Chef::Knife::BootstrapWindowsWinrm).to receive(:new).and_return(@bootstrap_winrm)
      expect(@bootstrap_winrm).to receive(:run)
      expect(knife_ec2_create).not_to receive(:ssh_override_winrm)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
    end

    it "set default distro to windows-chef-client-msi for windows" do
      knife_ec2_create.config[:winrm_password] = 'winrm-password'
      knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      @bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      allow(Chef::Knife::BootstrapWindowsWinrm).to receive(:new).and_return(@bootstrap_winrm)
      expect(@bootstrap_winrm).to receive(:run)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(true)
      expect(knife_ec2_create).to receive(:default_bootstrap_template).and_return("windows-chef-client-msi")
      knife_ec2_create.run
    end

    it "bootstraps via the SSH protocol" do
      knife_ec2_create.config[:bootstrap_protocol] = 'ssh'
      bootstrap_win_ssh = Chef::Knife::BootstrapWindowsSsh.new
      allow(Chef::Knife::BootstrapWindowsSsh).to receive(:new).and_return(bootstrap_win_ssh)
      expect(bootstrap_win_ssh).to receive(:run)
      expect(knife_ec2_create).to receive(:ssh_override_winrm)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
    end

    it "should use configured SSH port" do
      knife_ec2_create.config[:bootstrap_protocol] = 'ssh'
      knife_ec2_create.config[:ssh_port] = 422

      expect(knife_ec2_create).to receive(:tcp_test_ssh).with('ec2-75.101.253.10.compute-1.amazonaws.com', 422).and_return(true)

      bootstrap_win_ssh = Chef::Knife::BootstrapWindowsSsh.new
      allow(Chef::Knife::BootstrapWindowsSsh).to receive(:new).and_return(bootstrap_win_ssh)
      expect(bootstrap_win_ssh).to receive(:run)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      knife_ec2_create.run
    end

    it "should never invoke linux bootstrap" do
      knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      allow(knife_ec2_create).to receive(:windows_password).and_return("")
      expect(knife_ec2_create).not_to receive(:bootstrap_for_linux_node)
      expect(new_ec2_server).to receive(:wait_for).and_return(true)
      allow(knife_ec2_create).to receive(:bootstrap_for_windows_node).and_return double("bootstrap", :run => true)
      knife_ec2_create.run
    end

    it "waits for EC2 to generate password if not supplied" do
      knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      knife_ec2_create.config[:winrm_password] = nil
      expect(knife_ec2_create).to receive(:windows_password).and_return("")
      allow(new_ec2_server).to receive(:wait_for).and_return(true)
      allow(knife_ec2_create).to receive(:check_windows_password_available).and_return(true)
      bootstrap_winrm = Chef::Knife::BootstrapWindowsWinrm.new
      allow(Chef::Knife::BootstrapWindowsWinrm).to receive(:new).and_return(bootstrap_winrm)
      expect(bootstrap_winrm).to receive(:run)
      knife_ec2_create.run
    end
  end

  describe "when setting tags" do
    before do
      expect(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      allow(knife_ec2_create).to receive(:bootstrap_for_linux_node).and_return double("bootstrap", :run => true)
      allow(ec2_connection).to receive(:servers).and_return(ec2_servers)
      expect(ec2_connection).to receive(:addresses)
      allow(new_ec2_server).to receive(:wait_for).and_return(true)
      allow(ec2_servers).to receive(:create).and_return(new_ec2_server)
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
    end

    it "sets the Name tag to the instance id by default" do
      expect(ec2_connection.tags).to receive(:create).with(:key => "Name",
                                                        :value => new_ec2_server.id,
                                                        :resource_id => new_ec2_server.id)
      knife_ec2_create.run
    end

    it "sets the Name tag to the chef_node_name when given" do
      knife_ec2_create.config[:chef_node_name] = "wombat"
      expect(ec2_connection.tags).to receive(:create).with(:key => "Name",
                                                        :value => "wombat",
                                                        :resource_id => new_ec2_server.id)
      knife_ec2_create.run
    end

    it "sets the Name tag to the specified name when given --tags Name=NAME" do
      knife_ec2_create.config[:tags] = ["Name=bobcat"]
      expect(ec2_connection.tags).to receive(:create).with(:key => "Name",
                                                        :value => "bobcat",
                                                        :resource_id => new_ec2_server.id)
      knife_ec2_create.run
    end

    it "sets arbitrary tags" do
      knife_ec2_create.config[:tags] = ["foo=bar"]
      expect(ec2_connection.tags).to receive(:create).with(:key => "foo",
                                                        :value => "bar",
                                                        :resource_id => new_ec2_server.id)
      knife_ec2_create.run
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

      it "sets encrypted_data_bag_secret" do
        expect(bootstrap.config[:encrypted_data_bag_secret]).to eql("sys-knife-secret")
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

      it "sets encrypted_data_bag_secret_file" do
        expect(bootstrap.config[:encrypted_data_bag_secret_file]).to eql("sys-knife-secret-file")
      end

      it "prefers using a provided value instead of the knife confiuration" do
        subject.config[:secret_file] = "cli-provided-secret-file"
        expect(bootstrap.config[:secret_file]).to eql("cli-provided-secret-file")
      end
    end

    context 'S3-based secret' do
      before(:each) do
        Chef::Config[:knife][:s3_secret] =
          's3://test.bucket/folder/encrypted_data_bag_secret'
        @secret_content = "TEST DATA BAG SECRET\n"
        allow(knife_ec2_create).to receive(:s3_secret).and_return(@secret_content)
      end

      it 'sets the secret to the expected test string' do
        expect(bootstrap.config[:secret]).to eql(@secret_content)
      end
    end
  end

  describe 'S3 secret test cases' do
    before do
      Chef::Config[:knife][:s3_secret] =
        's3://test.bucket/folder/encrypted_data_bag_secret'
      knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'
      @secret_content = "TEST DATA BAG SECRET\n"
      allow(knife_ec2_create).to receive(:s3_secret).and_return(@secret_content)
      allow(Chef::Knife).to receive(:Bootstrap)
      @bootstrap = knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name)
    end

    context 'when s3 secret option is passed' do
      it 'sets the s3 secret value to cl_secret key' do
        knife_ec2_create.bootstrap_common_params(@bootstrap)
        expect(Chef::Config[:knife][:cl_secret]).to eql(@secret_content)
      end
    end

    context 'when s3 secret option is not passed' do
      it 'sets the cl_secret value to nil' do
        Chef::Config[:knife].delete(:s3_secret)
        Chef::Config[:knife].delete(:cl_secret)
        knife_ec2_create.bootstrap_common_params(@bootstrap)
        expect(Chef::Config[:knife][:cl_secret]).to eql(nil)
      end
    end
  end

  context "when deprecated aws_ssh_key_id option is used in knife config and no ssh-key is supplied on the CLI" do
    before do
      Chef::Config[:knife][:aws_ssh_key_id] = "mykey"
      Chef::Config[:knife].delete(:ssh_key_name)
      @aws_key = Chef::Config[:knife][:aws_ssh_key_id]
      allow(knife_ec2_create).to receive(:ami).and_return(false)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
    end

    it "gives warning message and creates the attribute with the required name" do
      expect(knife_ec2_create.ui).to receive(:warn).with("Use of aws_ssh_key_id option in knife.rb config is deprecated, use ssh_key_name option instead.")
      knife_ec2_create.validate!
      expect(Chef::Config[:knife][:ssh_key_name]).to eq(@aws_key)
    end
  end

  context "when deprecated aws_ssh_key_id option is used in knife config but ssh-key is also supplied on the CLI" do
    before do
      Chef::Config[:knife][:aws_ssh_key_id] = "mykey"
      @aws_key = Chef::Config[:knife][:aws_ssh_key_id]
      allow(knife_ec2_create).to receive(:ami).and_return(false)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
    end

    it "gives warning message and gives preference to CLI value over knife config's value" do
      expect(knife_ec2_create.ui).to receive(:warn).with("Use of aws_ssh_key_id option in knife.rb config is deprecated, use ssh_key_name option instead.")
      knife_ec2_create.validate!
      expect(Chef::Config[:knife][:ssh_key_name]).to_not eq(@aws_key)
    end
  end

  context "when ssh_key_name option is used in knife config instead of deprecated aws_ssh_key_id option" do
    before do
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      allow(knife_ec2_create).to receive(:ami).and_return(false)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
    end

    it "does nothing" do
      knife_ec2_create.validate!
    end
  end

  context "when ssh_key_name option is used in knife config also it is passed on the CLI" do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
    end

    it "ssh-key passed over CLI gets preference over knife config value" do
      server_def = knife_ec2_create.create_server_def
      expect(server_def[:key_name]).to eq(knife_ec2_create.config[:ssh_key_name])
    end
  end

  describe "when configuring the bootstrap process" do
    before do
      knife_ec2_create.config[:ssh_user] = "ubuntu"
      knife_ec2_create.config[:identity_file] = "~/.ssh/aws-key.pem"
      knife_ec2_create.config[:ssh_port] = 22
      knife_ec2_create.config[:ssh_gateway] = 'bastion.host.com'
      knife_ec2_create.config[:chef_node_name] = "blarf"
      knife_ec2_create.config[:template_file] = '~/.chef/templates/my-bootstrap.sh.erb'
      knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'
      knife_ec2_create.config[:run_list] = ['role[base]']
      knife_ec2_create.config[:first_boot_attributes] = "{'my_attributes':{'foo':'bar'}"
      knife_ec2_create.config[:first_boot_attributes_from_file] = "{'my_attributes':{'foo':'bar'}"


      @bootstrap = knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name)
    end

    include_examples "generic bootstrap configurations" do
      subject { knife_ec2_create }
      let(:bootstrap) { knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name) }
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server" do
      expect(@bootstrap.name_args).to eq(['ec2-75.101.253.10.compute-1.amazonaws.com'])
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      expect(@bootstrap.config[:first_boot_attributes]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "should set the bootstrap 'first_boot_attributes_from_file' correctly" do
      expect(@bootstrap.config[:first_boot_attributes_from_file]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "configures sets the bootstrap's run_list" do
      expect(@bootstrap.config[:run_list]).to eq(['role[base]'])
    end

    it "configures the bootstrap to use the correct ssh_user login" do
      expect(@bootstrap.config[:ssh_user]).to eq('ubuntu')
    end

    it "configures the bootstrap to use the correct ssh_gateway host" do
      expect(@bootstrap.config[:ssh_gateway]).to eq('bastion.host.com')
    end

    it "configures the bootstrap to use the correct ssh identity file" do
      expect(@bootstrap.config[:identity_file]).to eq("~/.ssh/aws-key.pem")
    end

    it "configures the bootstrap to use the correct ssh_port number" do
      expect(@bootstrap.config[:ssh_port]).to eq(22)
    end

    it "configures the bootstrap to use the configured node name if provided" do
      expect(@bootstrap.config[:chef_node_name]).to eq('blarf')
    end

    it "configures the bootstrap to use the EC2 server id if no explicit node name is set" do
      knife_ec2_create.config[:chef_node_name] = nil

      bootstrap = knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name)
      expect(bootstrap.config[:chef_node_name]).to eq(new_ec2_server.id)
    end

    it "configures the bootstrap to use prerelease versions of chef if specified" do
      expect(@bootstrap.config[:prerelease]).to be_falsey

      knife_ec2_create.config[:prerelease] = true

      bootstrap = knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name)
      expect(bootstrap.config[:prerelease]).to eq(true)
    end

    it "configures the bootstrap to use the desired distro-specific bootstrap script" do
      expect(@bootstrap.config[:distro]).to eq('ubuntu-10.04-magic-sparkles')
    end

    it "configures the bootstrap to use sudo" do
      expect(@bootstrap.config[:use_sudo]).to eq(true)
    end

    it "configured the bootstrap to use the desired template" do
      expect(@bootstrap.config[:template_file]).to eq('~/.chef/templates/my-bootstrap.sh.erb')
    end

    it "configured the bootstrap to set an ec2 hint (via Chef::Config)" do
      expect(Chef::Config[:knife][:hints]["ec2"]).not_to be_nil
    end
  end

  describe "when configuring the ssh bootstrap process for windows" do
    before do
      allow(knife_ec2_create).to receive(:fetch_server_fqdn).and_return("SERVERNAME")
      knife_ec2_create.config[:ssh_user] = "administrator"
      knife_ec2_create.config[:ssh_password] = "password"
      knife_ec2_create.config[:ssh_port] = 22
      knife_ec2_create.config[:forward_agent] = true
      knife_ec2_create.config[:bootstrap_protocol] = 'ssh'
      knife_ec2_create.config[:image] = '12345'
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(true)
      @bootstrap = knife_ec2_create.bootstrap_for_windows_node(new_ec2_server, new_ec2_server.dns_name)
    end

    it "sets the bootstrap 'forward_agent' correctly" do
      expect(@bootstrap.config[:forward_agent]).to eq(true)
    end
  end

  describe "when configuring the winrm bootstrap process for windows" do
    before do
      allow(knife_ec2_create).to receive(:fetch_server_fqdn).and_return("SERVERNAME")
      knife_ec2_create.config[:winrm_user] = "Administrator"
      knife_ec2_create.config[:winrm_password] = "password"
      knife_ec2_create.config[:winrm_port] = 12345
      knife_ec2_create.config[:winrm_transport] = 'ssl'
      knife_ec2_create.config[:kerberos_realm] = "realm"
      knife_ec2_create.config[:bootstrap_protocol] = 'winrm'
      knife_ec2_create.config[:kerberos_service] = "service"
      knife_ec2_create.config[:chef_node_name] = "blarf"
      knife_ec2_create.config[:template_file] = '~/.chef/templates/my-bootstrap.sh.erb'
      knife_ec2_create.config[:distro] = 'ubuntu-10.04-magic-sparkles'
      knife_ec2_create.config[:run_list] = ['role[base]']
      knife_ec2_create.config[:first_boot_attributes] = "{'my_attributes':{'foo':'bar'}"
      knife_ec2_create.config[:winrm_ssl_verify_mode] = 'verify_peer'
      knife_ec2_create.config[:msi_url] = 'https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi'
      knife_ec2_create.config[:install_as_service] = true
      knife_ec2_create.config[:session_timeout] = "90"
      @bootstrap = knife_ec2_create.bootstrap_for_windows_node(new_ec2_server, new_ec2_server.dns_name)
   end

    include_examples "generic bootstrap configurations" do
      subject { knife_ec2_create }
      let(:bootstrap) { knife_ec2_create.bootstrap_for_linux_node(new_ec2_server, new_ec2_server.dns_name) }
    end

    it "should set the winrm username correctly" do
      expect(@bootstrap.config[:winrm_user]).to eq(knife_ec2_create.config[:winrm_user])
    end
    it "should set the winrm password correctly" do
      expect(@bootstrap.config[:winrm_password]).to eq(knife_ec2_create.config[:winrm_password])
    end

    it "should set the winrm port correctly" do
      expect(@bootstrap.config[:winrm_port]).to eq(knife_ec2_create.config[:winrm_port])
    end

    it "should set the winrm transport layer correctly" do
      expect(@bootstrap.config[:winrm_transport]).to eq(knife_ec2_create.config[:winrm_transport])
    end

    it "should set the kerberos realm correctly" do
      expect(@bootstrap.config[:kerberos_realm]).to eq(knife_ec2_create.config[:kerberos_realm])
    end

    it "should set the kerberos service correctly" do
      expect(@bootstrap.config[:kerberos_service]).to eq(knife_ec2_create.config[:kerberos_service])
    end

    it "should set the bootstrap 'name argument' to the Windows/AD hostname of the EC2 server" do
      expect(@bootstrap.name_args).to eq(["SERVERNAME"])
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server when AD/Kerberos is not used" do
      knife_ec2_create.config[:kerberos_realm] = nil
      @bootstrap = knife_ec2_create.bootstrap_for_windows_node(new_ec2_server, new_ec2_server.dns_name)
      expect(@bootstrap.name_args).to eq(['ec2-75.101.253.10.compute-1.amazonaws.com'])
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      expect(@bootstrap.config[:first_boot_attributes]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "should set the bootstrap 'winrm_ssl_verify_mode' correctly" do
      expect(@bootstrap.config[:winrm_ssl_verify_mode]).to eq("verify_peer")
    end

    it "should set the bootstrap 'msi_url' correctly" do
      expect(@bootstrap.config[:msi_url]).to eq('https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi')
    end

    it "should set the bootstrap 'install_as_service' correctly" do
      expect(@bootstrap.config[:install_as_service]).to eq(knife_ec2_create.config[:install_as_service])
    end

    it "should set the bootstrap 'session_timeout' correctly" do
      expect(@bootstrap.config[:session_timeout]).to eq(knife_ec2_create.config[:session_timeout])
    end

    it "configures sets the bootstrap's run_list" do
      expect(@bootstrap.config[:run_list]).to eq(['role[base]'])
    end

    it "configures auth_timeout for bootstrap to default to 25 minutes" do
      expect(knife_ec2_create.options[:auth_timeout][:default]).to eq(25)
    end

    it "configures auth_timeout for bootstrap according to plugin auth_timeout config" do
      knife_ec2_create.config[:auth_timeout] = 5
      bootstrap = knife_ec2_create.bootstrap_for_windows_node(new_ec2_server, new_ec2_server.dns_name)
      expect(bootstrap.config[:auth_timeout]).to eq(5)
    end
 end

  describe "when validating the command-line parameters" do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      allow(knife_ec2_create.ui).to receive(:error)
      allow(knife_ec2_create.ui).to receive(:msg)
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
        allow(File).to receive(:read).
          and_return("AWSAccessKeyId=#{@access_key_id}\nAWSSecretKey=#{@secret_key}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "reads DOS Line endings" do
        allow(File).to receive(:read).
          and_return("AWSAccessKeyId=#{@access_key_id}\r\nAWSSecretKey=#{@secret_key}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end
      it "reads UNIX Line endings for new format" do
        allow(File).to receive(:read).
          and_return("[default]\naws_access_key_id=#{@access_key_id}\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "reads DOS Line endings for new format" do
        allow(File).to receive(:read).
          and_return("[default]\naws_access_key_id=#{@access_key_id}\r\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "loads the correct profile" do
        Chef::Config[:knife][:aws_profile] = 'other'
        allow(File).to receive(:read).
          and_return("[default]\naws_access_key_id=TESTKEY\r\naws_secret_access_key=TESTSECRET\n\n[other]\naws_access_key_id=#{@access_key_id}\r\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      context "when invalid --aws-profile is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_profile] = 'xyz'
          allow(File).to receive(:read).and_return("[default]\naws_access_key_id=TESTKEY\r\naws_secret_access_key=TESTSECRET")
          expect{ knife_ec2_create.validate! }.to raise_error("The provided --aws-profile 'xyz' is invalid.")
        end
      end
    end


    describe "when reading aws_config_file" do
      before do
        Chef::Config[:knife][:aws_config_file] = '/apple/pear'
        @region = 'region'
      end

      it "reads UNIX Line endings" do
        allow(File).to receive(:read).
          and_return("[default]\r\nregion=#{@region}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "reads DOS Line endings" do
        allow(File).to receive(:read).
          and_return("[default]\r\nregion=#{@region}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end
      it "reads UNIX Line endings for new format" do
         allow(File).to receive(:read).
          and_return("[default]\nregion=#{@region}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "reads DOS Line endings for new format" do
         allow(File).to receive(:read).
          and_return("[default]\nregion=#{@region}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "loads the correct profile" do
        Chef::Config[:knife][:aws_profile] = 'other'
        allow(File).to receive(:read).
          and_return("[default]\nregion=TESTREGION\n\n[profile other]\nregion=#{@region}")
        knife_ec2_create.validate!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      context "when invalid --aws-profile is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_profile] = 'xyz'
          allow(File).to receive(:read).and_return("[default]\nregion=TESTREGION")
          expect{ knife_ec2_create.validate! }.to raise_error("The provided --aws-profile 'profile xyz' is invalid.")
        end
      end

      context "when aws_profile is passed a 'default' from CLI or knife.rb file" do
        it 'loads the default profile successfully' do
          Chef::Config[:knife][:aws_profile] = 'default'
          allow(File).to receive(:read).and_return("[default]\nregion=#{@region}\n\n[profile other]\nregion=TESTREGION")
          knife_ec2_create.validate!
          expect(Chef::Config[:knife][:region]).to eq(@region)
        end
      end
    end

    it 'understands that file:// validation key URIs are just paths' do
      Chef::Config[:knife][:validation_key_url] = 'file:///foo/bar'
      expect(knife_ec2_create.validation_key_path).to eq('/foo/bar')
    end

    it 'returns a path to a tmp file when presented with a URI for the ' \
      'validation key' do
      Chef::Config[:knife][:validation_key_url] = @validation_key_url

      allow(knife_ec2_create).to receive_message_chain(:validation_key_tmpfile, :path).and_return(@validation_key_file)

      expect(knife_ec2_create.validation_key_path).to eq(@validation_key_file)
    end

    it "disallows security group names when using a VPC" do
      knife_ec2_create.config[:subnet_id] = @subnet_1_id
      knife_ec2_create.config[:security_group_ids] = 'sg-aabbccdd'
      knife_ec2_create.config[:security_groups] = 'groupname'

      allow(ec2_connection).to receive_message_chain(:subnets, :get).with(@subnet_1_id).and_return(@subnet_1)

      expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
    end

    it 'disallows invalid network interface ids' do
      knife_ec2_create.config[:network_interfaces] = ['INVALID_ID']

      expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
    end

    it 'disallows network interfaces not in the right VPC' do
      knife_ec2_create.config[:subnet_id] = @subnet_1_id
      knife_ec2_create.config[:security_group_ids] = 'sg-aabbccdd'
      knife_ec2_create.config[:security_groups] = 'groupname'

      allow(ec2_connection).to receive_message_chain(:subnets, :get).with(@subnet_1_id).and_return(@subnet_1)

      allow(ec2_connection).to receive_message_chain(:network_interfaces, :all).and_return [
        double('network_interfaces', network_interface_id: 'eni-12345678', vpc_id: 'another_vpc'),
        double('network_interfaces', network_interface_id: 'eni-87654321', vpc_id: my_vpc)
      ]

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows private ips when not using a VPC" do
      knife_ec2_create.config[:private_ip_address] = '10.0.0.10'

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows specifying credentials file and aws keys" do
      Chef::Config[:knife][:aws_credential_file] = '/apple/pear'
      allow(File).to receive(:read).and_return("AWSAccessKeyId=b\nAWSSecretKey=a")

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows associate public ip option when not using a VPC" do
      knife_ec2_create.config[:associate_public_ip] = true
      knife_ec2_create.config[:subnet_id] = nil

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows setting only one of the two ClassicLink options" do
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = nil

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows ClassicLink with VPC" do
      knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = @vpc_security_group_ids

      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows ebs provisioned iops option when not using ebs volume type" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = nil

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows ebs provisioned iops option when not using ebs volume type 'io1'" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = "standard"

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows ebs volume type if its other than 'io1' or 'gp2' or 'standard'" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = 'invalid'

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    it "disallows 'io1' ebs volume type when not using ebs provisioned iops" do
      knife_ec2_create.config[:ebs_provisioned_iops] = nil
      knife_ec2_create.config[:ebs_volume_type] = 'io1'

      expect { knife_ec2_create.validate! }.to raise_error SystemExit
    end

    context "when ebs_encrypted option specified" do
      it "not raise any validation error if valid ebs_size specified" do
        knife_ec2_create.config[:ebs_size] = "8"
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to_not receive(:error).with(" --ebs-encrypted option requires valid --ebs-size to be specified.")
        knife_ec2_create.validate!
      end

      it "raise error on missing ebs_size" do
        knife_ec2_create.config[:ebs_size] = nil
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-encrypted option requires valid --ebs-size to be specified.")
        expect { knife_ec2_create.validate! }.to raise_error SystemExit
      end

      it "raise error if invalid ebs_size specified for 'standard' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "1055"
        knife_ec2_create.config[:ebs_volume_type] = 'standard'
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 1-1024 for 'standard' ebs volume type.")
        expect { knife_ec2_create.validate! }.to raise_error SystemExit
      end

      it "raise error on invalid ebs_size specified for 'gp2' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "16500"
        knife_ec2_create.config[:ebs_volume_type] = 'gp2'
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 1-16384 for 'gp2' ebs volume type.")
        expect { knife_ec2_create.validate! }.to raise_error SystemExit
      end

      it "raise error on invalid ebs_size specified for 'io1' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "3"
        knife_ec2_create.config[:ebs_provisioned_iops] = "200"
        knife_ec2_create.config[:ebs_volume_type] = 'io1'
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 4-16384 for 'io1' ebs volume type.")
        expect { knife_ec2_create.validate! }.to raise_error SystemExit
      end
    end
  end

  describe "when creating the connection" do
    describe "when use_iam_profile is true" do
      before do
        Chef::Config[:knife].delete(:aws_access_key_id)
        Chef::Config[:knife].delete(:aws_secret_access_key)
      end

      it "creates a connection without access keys" do
        knife_ec2_create.config[:use_iam_profile] = true
        expect(Fog::Compute::AWS).to receive(:new).with(hash_including(:use_iam_profile => true)).and_return(ec2_connection)
        knife_ec2_create.connection
      end
    end

    describe "when aws_session_token is present" do
      it "creates a connection using the session token" do
        knife_ec2_create.config[:aws_session_token] = 'session-token'
        expect(Fog::Compute::AWS).to receive(:new).with(hash_including(:aws_session_token => 'session-token')).and_return(ec2_connection)
        knife_ec2_create.connection
      end
    end
  end

  describe "when creating the server definition" do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
    end

    it "sets the specified placement_group" do
      knife_ec2_create.config[:placement_group] = ['some_placement_group']
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:placement_group]).to eq(['some_placement_group'])
    end

    it "sets the specified security group names" do
      knife_ec2_create.config[:security_groups] = ['groupname']
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:groups]).to eq(['groupname'])
    end

    it "sets the specified security group ids" do
      knife_ec2_create.config[:security_group_ids] = ['sg-aabbccdd', 'sg-3764sdss',  'sg-aab343ytre']
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:security_group_ids]).to eq(['sg-aabbccdd', 'sg-3764sdss', 'sg-aab343ytre'])
    end

    it "sets the image id from CLI arguments over knife config" do
      knife_ec2_create.config[:image] = "ami-aaa"
      Chef::Config[:knife][:image] = "ami-zzz"
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:image_id]).to eq("ami-aaa")
    end

    it "sets the flavor id from CLI arguments over knife config" do
      knife_ec2_create.config[:flavor] = "massive"
      Chef::Config[:knife][:flavor] = "bitty"
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:flavor_id]).to eq("massive")
    end

    it "sets the availability zone from CLI arguments over knife config" do
      knife_ec2_create.config[:availability_zone] = "dis-one"
      Chef::Config[:knife][:availability_zone] = "dat-one"
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:availability_zone]).to eq("dis-one")
    end

    it "adds the specified ephemeral device mappings" do
      knife_ec2_create.config[:ephemeral] = [ "/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde" ]
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:block_device_mapping]).to eq([{ "VirtualName" => "ephemeral0", "DeviceName" => "/dev/sdb" },
                                                   { "VirtualName" => "ephemeral1", "DeviceName" => "/dev/sdc" },
                                                   { "VirtualName" => "ephemeral2", "DeviceName" => "/dev/sdd" },
                                                   { "VirtualName" => "ephemeral3", "DeviceName" => "/dev/sde" }])
    end

    it "sets the specified private ip address" do
      knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      knife_ec2_create.config[:private_ip_address] = '10.0.0.10'
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:subnet_id]).to eq('subnet-1a2b3c4d')
      expect(server_def[:private_ip_address]).to eq('10.0.0.10')
    end

    it "sets the IAM server role when one is specified" do
      knife_ec2_create.config[:iam_instance_profile] = ['iam-role']
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:iam_instance_profile_name]).to eq(['iam-role'])
    end

    it "doesn't set an IAM server role by default" do
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:iam_instance_profile_name]).to eq(nil)
    end

    it "doesn't use IAM profile by default" do
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:use_iam_profile]).to eq(nil)
    end

    it 'Set Tenancy Dedicated when both VPC mode and Flag is True' do
      knife_ec2_create.config[:dedicated_instance] = true
      allow(knife_ec2_create).to receive_messages(:vpc_mode? => true)
      server_def = knife_ec2_create.create_server_def
      expect(server_def[:tenancy]).to eq("dedicated")
    end

    it 'Tenancy should be default with no vpc mode even is specified' do
      knife_ec2_create.config[:dedicated_instance] = true
      server_def = knife_ec2_create.create_server_def
      expect(server_def[:tenancy]).to eq(nil)
    end

    it 'Tenancy should be default with vpc but not requested' do
      allow(knife_ec2_create).to receive_messages(:vpc_mode? => true)
      server_def = knife_ec2_create.create_server_def
      expect(server_def[:tenancy]).to eq(nil)
    end

    it "sets associate_public_ip to true if specified and in vpc_mode" do
      knife_ec2_create.config[:subnet_id] = 'subnet-1a2b3c4d'
      knife_ec2_create.config[:associate_public_ip] = true
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:subnet_id]).to eq('subnet-1a2b3c4d')
      expect(server_def[:associate_public_ip]).to eq(true)
    end

    it "sets the spot price" do
      knife_ec2_create.config[:spot_price] = '1.99'
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:price]).to eq('1.99')
    end

    it "sets the spot instance request type as persistent" do
      knife_ec2_create.config[:spot_request_type] = 'persistent'
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:request_type]).to eq('persistent')
    end

    it "sets the spot instance request type as one-time" do
      knife_ec2_create.config[:spot_request_type] = 'one-time'
      server_def = knife_ec2_create.create_server_def

      expect(server_def[:request_type]).to eq('one-time')
    end

    context "when using ebs volume type and ebs provisioned iops rate options" do
      before do
        allow(knife_ec2_create).to receive_message_chain(:ami, :root_device_type).and_return("ebs")
        allow(knife_ec2_create).to receive_message_chain(:ami, :block_device_mapping).and_return([{"iops" => 123}])
        allow(knife_ec2_create).to receive(:msg)
        allow(knife_ec2_create).to receive(:puts)
      end

      it "sets the specified 'standard' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = 'standard'
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:block_device_mapping].first['Ebs.VolumeType']).to eq('standard')
      end

      it "sets the specified 'io1' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = 'io1'
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:block_device_mapping].first['Ebs.VolumeType']).to eq('io1')
      end

      it "sets the specified 'gp2' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = 'gp2'
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:block_device_mapping].first['Ebs.VolumeType']).to eq('gp2')
      end

      it "sets the specified ebs provisioned iops rate" do
        knife_ec2_create.config[:ebs_provisioned_iops] = '1234'
        knife_ec2_create.config[:ebs_volume_type] = 'io1'
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:block_device_mapping].first['Ebs.Iops']).to eq('1234')
      end

      it "disallows non integer ebs provisioned iops rate" do
        knife_ec2_create.config[:ebs_provisioned_iops] = "123abcd"

        expect { knife_ec2_create.create_server_def }.to raise_error SystemExit
      end

      it "sets the iops rate from ami" do
        knife_ec2_create.config[:ebs_volume_type] = 'io1'
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:block_device_mapping].first['Ebs.Iops']).to eq('123')
      end
    end
  end

  describe "wait_for_sshd" do
    let(:gateway) { 'test.gateway.com' }
    let(:hostname) { 'test.host.com' }

    it "should wait for tunnelled ssh if a ssh gateway is provided" do
      allow(knife_ec2_create).to receive(:get_ssh_gateway_for).and_return(gateway)
      expect(knife_ec2_create).to receive(:wait_for_tunnelled_sshd).with(gateway, hostname)
      knife_ec2_create.wait_for_sshd(hostname)
    end

    it "should wait for direct ssh if a ssh gateway is not provided" do
      allow(knife_ec2_create).to receive(:get_ssh_gateway_for).and_return(nil)
      knife_ec2_create.config[:ssh_port] = 22
      expect(knife_ec2_create).to receive(:wait_for_direct_sshd).with(hostname, 22)
      knife_ec2_create.wait_for_sshd(hostname)
    end
  end

  describe "get_ssh_gateway_for" do
    let(:gateway) { 'test.gateway.com' }
    let(:hostname) { 'test.host.com' }

    it "should give precedence to the ssh gateway specified in the knife configuration" do
      allow(Net::SSH::Config).to receive(:for).and_return(:proxy => Net::SSH::Proxy::Command.new("ssh some.other.gateway.com nc %h %p"))
      knife_ec2_create.config[:ssh_gateway] = gateway
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to eq(gateway)
    end

    it "should return the ssh gateway specified in the ssh configuration even if the config option is not set" do
      # This should already be false, but test this explicitly for regression
      knife_ec2_create.config[:ssh_gateway] = false
      allow(Net::SSH::Config).to receive(:for).and_return(:proxy => Net::SSH::Proxy::Command.new("ssh #{gateway} nc %h %p"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to eq(gateway)
    end

    it "should return nil if the ssh gateway cannot be parsed from the ssh proxy command" do
      allow(Net::SSH::Config).to receive(:for).and_return(:proxy => Net::SSH::Proxy::Command.new("cannot parse host"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

    it "should return nil if the ssh proxy is not a proxy command" do
      allow(Net::SSH::Config).to receive(:for).and_return(:proxy => Net::SSH::Proxy::HTTP.new("httphost.com"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

    it "returns nil if the ssh config has no proxy" do
      allow(Net::SSH::Config).to receive(:for).and_return(:user => "darius")
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

  end

  describe "#subnet_public_ip_on_launch?" do
    before do
      allow(new_ec2_server).to receive_messages(:subnet_id => 'subnet-1a2b3c4d')
      allow(knife_ec2_create).to receive_messages(:server => new_ec2_server)
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
    end

    context "when auto_assign_public_ip is enabled" do
      it "returns true" do
        allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => true )
        expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(true)
      end
    end

    context "when auto_assign_public_ip is disabled" do
      it "returns false" do
        allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => false )
        expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(false)
      end
    end
  end

  describe "ssh_connect_host" do
    before(:each) do
      allow(new_ec2_server).to receive_messages(
        :dns_name => 'public.example.org',
        :private_ip_address => '192.168.1.100',
        :custom => 'custom',
        :public_ip_address => '111.111.111.111',
        :subnet_id => 'subnet-1a2b3c4d'
      )
      allow(knife_ec2_create).to receive_messages(:server => new_ec2_server)
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
    end

    describe "by default" do
      it 'should use public dns name' do
        expect(knife_ec2_create.ssh_connect_host).to eq('public.example.org')
      end
    end

    describe "when dns name not exist" do
      it 'should use public_ip_address ' do
        allow(new_ec2_server).to receive(:dns_name).and_return(nil)
        expect(knife_ec2_create.ssh_connect_host).to eq('111.111.111.111')
      end
    end

    context "when vpc_mode? is true" do
      before do
        allow(knife_ec2_create).to receive_messages(:vpc_mode? => true)
      end

      context "subnet_public_ip_on_launch? is true" do
        it "uses the dns_name or public_ip_address" do
          allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => true )
          expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(true)
          expect(knife_ec2_create.ssh_connect_host).to eq('public.example.org')
        end
      end

      context "--associate-public-ip is specified" do
        it "uses the dns_name or public_ip_address" do
          knife_ec2_create.config[:associate_public_ip] = true
          allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => false )
          expect(knife_ec2_create.ssh_connect_host).to eq('public.example.org')
        end
      end

      context "--associate-eip is specified" do
        it "uses the dns_name or public_ip_address" do
          knife_ec2_create.config[:associate_eip] = '111.111.111.111'
          allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => false )
          expect(knife_ec2_create.ssh_connect_host).to eq('public.example.org')
        end
      end

      context "with no other ip flags" do
        it 'uses private_ip_address' do
          allow(ec2_connection).to receive_message_chain(:subnets, :get).and_return double( :map_public_ip_on_launch => false )
          expect(knife_ec2_create.ssh_connect_host).to eq('192.168.1.100')
        end
      end
    end

    describe "with custom server attribute" do
      it 'should use custom server attribute' do
        knife_ec2_create.config[:server_connect_attribute] = 'custom'
        expect(knife_ec2_create.ssh_connect_host).to eq('custom')
      end
    end
  end

  describe "tunnel_test_ssh" do
    let(:gateway_host) { 'test.gateway.com' }
    let(:gateway) { double('gateway') }
    let(:hostname) { 'test.host.com' }
    let(:local_port) { 23 }

    before(:each) do
      allow(knife_ec2_create).to receive(:configure_ssh_gateway).and_return(gateway)
    end

    it "should test ssh through a gateway" do
      knife_ec2_create.config[:ssh_port] = 22
      expect(gateway).to receive(:open).with(hostname, 22).and_yield(local_port)
      expect(knife_ec2_create).to receive(:tcp_test_ssh).with('localhost', local_port).and_return(true)
      expect(knife_ec2_create.tunnel_test_ssh(gateway_host, hostname)).to eq(true)
    end
  end

  describe "configure_ssh_gateway" do
    let(:gateway_host) { 'test.gateway.com' }
    let(:gateway_user) { 'gateway_user' }

    it "configures a ssh gateway with no user and the default port when the SSH Config is empty" do
      allow(Net::SSH::Config).to receive(:for).and_return({})
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, :port => 22)
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures a ssh gateway with the user specified in the SSH Config" do
      allow(Net::SSH::Config).to receive(:for).and_return({ :user => gateway_user })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, gateway_user, :port => 22)
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures a ssh gateway with the user specified in the ssh gateway string" do
      allow(Net::SSH::Config).to receive(:for).and_return({ :user => gateway_user })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, 'override_user', :port => 22)
      knife_ec2_create.configure_ssh_gateway("override_user@#{gateway_host}")
    end

    it "configures a ssh gateway with the port specified in the ssh gateway string" do
      allow(Net::SSH::Config).to receive(:for).and_return({})
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, :port => '24')
      knife_ec2_create.configure_ssh_gateway("#{gateway_host}:24")
    end

    it "configures a ssh gateway with the keys specified in the SSH Config" do
      allow(Net::SSH::Config).to receive(:for).and_return({ :keys => ['configuredkey'] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, :port => 22, :keys => ['configuredkey'])
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures the ssh gateway with the key specified on the knife config / command line" do
      knife_ec2_create.config[:ssh_gateway_identity] = "/home/fireman/.ssh/gateway.pem"
      #Net::SSH::Config.stub(:for).and_return({ :keys => ['configuredkey'] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, :port => 22, :keys => ['/home/fireman/.ssh/gateway.pem'])
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "prefers the knife config over the ssh config for the gateway keys" do
      knife_ec2_create.config[:ssh_gateway_identity] = "/home/fireman/.ssh/gateway.pem"
      allow(Net::SSH::Config).to receive(:for).and_return({ :keys => ['not_this_key_dude'] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, :port => 22, :keys => ['/home/fireman/.ssh/gateway.pem'])
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end
  end

  describe "tcp_test_ssh" do
    # Normally we would only get the header after we send a client header, e.g. 'SSH-2.0-client'
    it "should return true if we get an ssh header" do
      knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      allow(TCPSocket).to receive(:new).and_return(StringIO.new("SSH-2.0-OpenSSH_6.1p1 Debian-4"))
      allow(IO).to receive(:select).and_return(true)
      expect(knife_ec2_create).to receive(:tcp_test_ssh).and_yield.and_return(true)
      knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22) {nil}
    end

    it "should return false if we do not get an ssh header" do
      knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      allow(TCPSocket).to receive(:new).and_return(StringIO.new(""))
      allow(IO).to receive(:select).and_return(true)
      expect(knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22)).to be_falsey
    end

    it "should return false if the socket isn't ready" do
      knife_ec2_create = Chef::Knife::Ec2ServerCreate.new
      allow(TCPSocket).to receive(:new)
      allow(IO).to receive(:select).and_return(false)
      expect(knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22)).to be_falsey
    end
  end

  describe 'ssl_config_user_data' do
    before do
      knife_ec2_create.config[:winrm_password] = "ec2@123"
    end

    context 'For domain user' do
      before do
        knife_ec2_create.config[:winrm_user] = "domain\\ec2"
        @ssl_config_data = <<-EOH

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

        EOH
      end

      it 'gets ssl config user data' do
        expect(knife_ec2_create.ssl_config_user_data).to be == @ssl_config_data
      end
    end

    context 'For local user' do
      before do
        knife_ec2_create.config[:winrm_user] = ".\\ec2"
        @ssl_config_data = <<-EOH
net user /add ec2 ec2@123;
net localgroup Administrators /add ec2;

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

        EOH

      end

      it 'gets ssl config user data' do
        expect(knife_ec2_create.ssl_config_user_data).to be == @ssl_config_data
      end
    end
  end

  describe 'ssl_config_data_already_exist?' do

    before(:each) do
      @user_user_data = 'user_user_data.ps1'
      knife_ec2_create.config[:winrm_user] = "domain\\ec2"
      knife_ec2_create.config[:winrm_password] = "ec2@123"
      knife_ec2_create.config[:aws_user_data] = @user_user_data
    end

    context 'ssl config data does not exist in user supplied user_data' do
      before do
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
user_command_1\\\\user_command_2\\\\user_command_3
user_command_4
          EOH
        end
      end

      it 'returns false' do
        expect(knife_ec2_create.ssl_config_data_already_exist?).to eq(false)
      end
    end

    context 'ssl config data already exist in user supplied user_data' do
      before do
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
user_command_1
user_command_2

<powershell>

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>

          EOH
        end
      end

      it 'returns false' do
        expect(knife_ec2_create.ssl_config_data_already_exist?).to eq(true)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:aws_user_data)
      FileUtils.rm_rf @user_user_data
    end
  end

  describe 'attach ssl config into user data when transport is ssl' do
    before(:each) do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
      knife_ec2_create.config[:winrm_transport] = "ssl"
      knife_ec2_create.config[:create_ssl_listener] = true
      knife_ec2_create.config[:winrm_user] = "domain\\ec2"
      knife_ec2_create.config[:winrm_password] = "ec2@123"
    end

    context 'when user_data script provided by user contains only <script> section' do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<script>

ipconfig > c:\\ipconfig_data.txt

</script>
          EOH
        end
        @server_def_user_data = <<-EOH
<script>

ipconfig > c:\\ipconfig_data.txt

</script>


<powershell>

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "appends ssl config to user supplied user_data after <script> tag section" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context 'when user_data script provided by user contains <powershell> section' do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt
</powershell>
          EOH
        end
        @server_def_user_data = <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "appends ssl config to user supplied user_data at the end of <powershell> tag section" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context 'when user_data script provided by user already contains ssl config code' do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
        EOH
        end
        @server_def_user_data = <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "does no modifications and passes user_data as it is to server_def" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context 'when user_data script provided by user has invalid syntax' do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

<script>

ipconfig > c:\\ipconfig_data.txt

</script>
        EOH
        end
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "gives error and exits" do
        expect(knife_ec2_create.ui).to receive(:error).with("Provided user_data file is invalid.")
        expect { knife_ec2_create.create_server_def }.to raise_error SystemExit
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context 'when user_data script provided by user has <powershell> and <script> tag sections' do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

</powershell>
<script>

ipconfig > c:\\ipconfig_data.txt

</script>
        EOH
        end
        @server_def_user_data = <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt


If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
<script>

ipconfig > c:\\ipconfig_data.txt

</script>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "appends ssl config to user supplied user_data at the end of <powershell> tag section" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data is not supplied by user on cli" do
      before do
        @server_def_user_data = <<-EOH
<powershell>

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

</powershell>
        EOH
      end

      it "creates user_data only with default ssl configuration" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end
    end

    context "when user has specified --no-create-ssl-listener along with his/her own user_data on cli" do
      before do
        knife_ec2_create.config[:create_ssl_listener] = false
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

</powershell>
<script>

ipconfig > c:\\ipconfig_data.txt

</script>
        EOH
        end
        @server_def_user_data = <<-EOH
<powershell>

Get-DscLocalConfigurationManager > c:\\dsc_data.txt

</powershell>
<script>

ipconfig > c:\\ipconfig_data.txt

</script>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "does not attach ssl config into the user_data supplied by user on cli" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user has specified --no-create-ssl-listener with no user_data on cli" do
      before do
        knife_ec2_create.config[:create_ssl_listener] = false
        @server_def_user_data = nil
      end

      it "creates nil or empty user_data" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:ssh_key_name)
      Chef::Config[:knife].delete(:ssh_key_name)
      knife_ec2_create.config.delete(:winrm_transport)
      knife_ec2_create.config.delete(:create_ssl_listener)
    end
  end

  describe "do not attach ssl config into user data when transport is plaintext" do
    before(:each) do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
      knife_ec2_create.config[:winrm_transport] = "plaintext"
    end

    context "when user_data is supplied on cli" do
      before do
        @user_user_data = 'user_user_data.ps1'
        File.open(@user_user_data,"w+") do |f|
          f.write <<-EOH
<script>

ipconfig > c:\\ipconfig_data.txt
netstat > c:\\netstat_data.txt

</script>
          EOH
        end
        knife_ec2_create.config[:aws_user_data] = @user_user_data
        @server_def_user_data = <<-EOH
<script>

ipconfig > c:\\ipconfig_data.txt
netstat > c:\\netstat_data.txt

</script>
        EOH
      end

      it "user_data is created only with user's user_data" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data is not supplied on cli" do
      before do
        @server_def_user_data = nil
      end

      it "creates nil or empty user_data" do
        server_def = knife_ec2_create.create_server_def

        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:ssh_key_name)
      Chef::Config[:knife].delete(:ssh_key_name)
      knife_ec2_create.config.delete(:winrm_transport)
    end
  end

  describe 'disable_api_termination option' do
    context 'spot instance' do
      context 'disable_api_termination is not passed on CLI or in knife config' do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
          knife_ec2_create.config[:spot_price] = 0.001
        end

        it "does not set disable_api_termination option in server_def" do
          server_def = knife_ec2_create.create_server_def
          expect(server_def[:disable_api_termination]).to be == nil
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to_not raise_error
        end
      end

      context 'disable_api_termination is passed on CLI' do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
          knife_ec2_create.config[:spot_price] = 0.001
          knife_ec2_create.config[:disable_api_termination] = true
        end

        it "raises error" do
          expect(knife_ec2_create.ui).to receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
        end
      end

      context 'disable_api_termination is passed in knife config' do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
          knife_ec2_create.config[:spot_price] = 0.001
          Chef::Config[:knife][:disable_api_termination] = true
        end

        it "raises error" do
          expect(knife_ec2_create.ui).to receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
        end
      end
    end

    context 'non-spot instance' do
      context 'when disable_api_termination option is not passed on the CLI or in the knife config' do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
        end

        it "sets disable_api_termination option in server_def with value as false" do
          server_def = knife_ec2_create.create_server_def
          expect(server_def[:disable_api_termination]).to be == false
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to_not raise_error
        end
      end

      context "when disable_api_termination option is passed on the CLI" do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
          knife_ec2_create.config[:disable_api_termination] = true
        end

        it "sets disable_api_termination option in server_def with value as true" do
          server_def = knife_ec2_create.create_server_def
          expect(server_def[:disable_api_termination]).to be == true
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to_not raise_error
        end
      end

      context "when disable_api_termination option is passed in the knife config" do
        before do
          allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
          Chef::Config[:knife][:disable_api_termination] = true
        end

        it "sets disable_api_termination option in server_def with value as true" do
          server_def = knife_ec2_create.create_server_def
          expect(server_def[:disable_api_termination]).to be == true
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.validate! }.to_not raise_error
        end
      end
    end
  end

  describe '--security-group-ids option' do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
    end

    context 'when comma seprated values are provided from cli' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(['--security-group-ids', 'sg-aabbccdd,sg-3764sdss,sg-00aa11bb'])}
      it 'creates array of security group ids' do
        server_def = ec2_server_create.create_server_def
        expect(server_def[:security_group_ids]).to eq(['sg-aabbccdd', 'sg-3764sdss', 'sg-00aa11bb'])
      end
    end

    context 'when mulitple values provided from cli for e.g. --security-group-ids sg-aab343ytr --security-group-ids sg-3764sdss' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(['--security-group-ids', 'sg-aab343ytr', '--security-group-ids', 'sg-3764sdss'])}
      it 'creates array of security group ids' do
        server_def = ec2_server_create.create_server_def
        expect(server_def[:security_group_ids]).to eq(['sg-aab343ytr', 'sg-3764sdss'])
      end
    end

    context 'when comma seprated input is provided from knife.rb' do
      it 'raises error' do
        Chef::Config[:knife][:security_group_ids] = 'sg-aabbccdd, sg-3764sdss, sg-00aa11bb'
        expect { knife_ec2_create.validate! }.to raise_error(SystemExit)
      end
    end

    context 'when security group ids array is provided from knife.rb' do
      it 'allows --security-group-ids set from an array in knife.rb' do
        Chef::Config[:knife][:security_group_ids] = ['sg-aabbccdd', 'sg-3764sdss', 'sg-00aa11bb']
        expect { knife_ec2_create.validate! }.to_not raise_error(SystemExit)
      end
    end
  end

  describe '--security-group-id option' do
    before do
      allow(Fog::Compute::AWS).to receive(:new).and_return(ec2_connection)
    end

    context 'when mulitple values provided from cli for e.g. -g sg-aab343ytr -g sg-3764sdss' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(['-g', 'sg-aab343ytr', '-g', 'sg-3764sdss'])}
      it 'creates array of security group ids' do
        server_def = ec2_server_create.create_server_def
        expect(server_def[:security_group_ids]).to eq(['sg-aab343ytr', 'sg-3764sdss'])
      end
    end

    context 'when single value provided from cli for e.g. --security-group-id 3764sdss' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(['--security-group-id', 'sg-aab343ytr'])}
      it 'creates array of security group ids' do
        server_def = ec2_server_create.create_server_def
        expect(server_def[:security_group_ids]).to eq(['sg-aab343ytr'])
      end
    end
  end
end
