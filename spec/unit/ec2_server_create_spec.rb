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

require File.expand_path("../../spec_helper", __FILE__)
require "net/ssh/proxy/http"
require "net/ssh/proxy/command"
require "net/ssh/gateway"
require "chef/util/path_helper"
require "aws-sdk-ec2"
Chef::Knife::Bootstrap.load_deps

describe Chef::Knife::Ec2ServerCreate do
  let(:knife_ec2_create) { Chef::Knife::Ec2ServerCreate.new }
  let(:ec2_connection)   { Aws::EC2::Client.new(stub_responses: true) }
  let(:ebs)              { OpenStruct.new(volume_size: 30, iops: 123) }
  let(:groups)           { [OpenStruct.new(name: "grp-646rswg")] }
  let(:placement)        { OpenStruct.new(tenancy: "default", group_name: "some_placement_group") }
  let(:state)            { OpenStruct.new(name: "running") }
  let(:security_groups)  { [OpenStruct.new(group_id: "s-gr446f", group_name: "default-vpc")] }
  let(:tags)             { [OpenStruct.new(key: "Name", value: "ec2-test")] }
  let(:block_device_mappings) { OpenStruct.new(ebs: ebs) }
  let(:network_interfaces)    { OpenStruct.new(subnet_id: "subnet-9d4a7b6") }
  let(:instance1) do
    OpenStruct.new(
      architecture: "x86_64",
      image_id: "ami-005bdb005fb00e791",
      instance_id: "i-00fe186450a2e8e97",
      instance_type: "t2.micro",
      key_name: "ssh_key_name",
      platform: "windows",
      name: "image-test",
      description: "test windows winrm image",
      block_device_mappings: [block_device_mappings],
      network_interfaces: [network_interfaces],
      groups: groups,
      placement: placement,
      state: state,
      security_groups: security_groups,
      tags: tags
    )
  end

  let(:ami) do
    OpenStruct.new(
      architecture: "x86_64",
      image_id: "ami-005bdb005fb00e791",
      platform: "windows",
      name: "image-test",
      description: "test windows winrm image",
      root_device_type: "ebs",
      block_device_mappings: [block_device_mappings]
    )
  end

  let(:elastic_address) do
    OpenStruct.new(
      allocation_id: "eipalloc-12345678",
      association_id: "eipassoc-12345678",
      domain: "vpc",
      instance_id: "i-00fe186450a2e8e97",
      network_interface_id: "eni-12345678",
      network_interface_owner_id: "123456789012",
      private_ip_address: "10.0.1.241",
      public_ip: "111.111.111.111"
    )
  end

  let(:elastic_address_response) do
    OpenStruct.new(
      addresses: [elastic_address]
    )
  end

  let(:server_instances)  { OpenStruct.new(groups: groups, instances: [instance1]) }
  let(:ec2_servers)       { OpenStruct.new(reservations: [server_instances]) }

  let(:server_attributes) do
    {
      image_id: "ami-005bdb005fb00e791",
      instance_type: "m1.small",
      groups: nil,
      key_name: "ssh_key_name",
      max_count: 1,
      min_count: 1,
      placement: {
        availability_zone: "us-west-2a",
        group_name: "some_placement_group",
      },
      security_group_ids: nil,
      iam_instance_profile: { name: nil },
      ebs_optimized: false,
      instance_initiated_shutdown_behavior: nil,
      chef_tag: nil,
    }
  end

  let(:ec2_server_attribs) do
    OpenStruct.new(id: "i-00fe186450a2e8e97",
      flavor_id: "m1.small",
      image_id: "ami-005bdb005fb00e791",
      placement_group: "some_placement_group",
      availability_zone: "us-west-2a",
      key_name: "ssh_key_name",
      groups: ["groupname"],
      security_group_ids: ["sg-00aa11bb"],
      public_dns_name: "ec2-75.101.253.10.compute-1.amazonaws.com",
      public_ip_address: "75.101.253.10",
      private_dns_name: "ip-10-251-75-20.ec2.internal",
      private_ip_address: "10.251.75.20",
      root_device_type: "ebs",
      block_device_mapping: [{ volume_id: 456 }],
      volume_id: "v-006eub006")
  end

  let(:my_vpc) { "vpc-12345678" }

  before(:each) do
    knife_ec2_create.initial_sleep_delay = 0
    allow(knife_ec2_create).to receive(:check_license)
    allow(knife_ec2_create).to receive(:connect!)
    allow(knife_ec2_create).to receive(:register_client)
    allow(knife_ec2_create).to receive(:render_template)
    allow(knife_ec2_create).to receive(:upload_bootstrap)
    allow(knife_ec2_create).to receive(:perform_bootstrap)
    allow(knife_ec2_create).to receive(:plugin_finalize)
    allow(knife_ec2_create).to receive(:ec2_connection).and_return ec2_connection
    allow(knife_ec2_create).to receive(:tcp_test_ssh)
    allow(knife_ec2_create).to receive(:msg_pair)
    allow(knife_ec2_create).to receive(:puts)
    allow(knife_ec2_create).to receive(:print)
    allow(ec2_connection).to receive(:describe_addresses).and_return(elastic_address_response)
    allow(ec2_connection).to receive(:tags).and_return double("create", create: true)
    allow(ec2_connection).to receive(:volume_tags).and_return double("create", create: true)
    allow(knife_ec2_create).to receive(:ami).and_return(ami)
    allow(knife_ec2_create).to receive(:tcp_test_winrm).and_return(true)
    allow(ec2_connection).to receive(:addresses).and_return [double("addesses", {
            domain: "standard",
            public_ip: "111.111.111.111",
            server_id: nil,
            allocation_id: "" })]

    allow(ec2_connection).to receive(:subnets).and_return [@subnet_1, @subnet_2]
    allow(ec2_connection).to receive_message_chain(:network_interfaces, :all).and_return [
      double("network_interfaces", network_interface_id: "eni-12345678"),
      double("network_interfaces", network_interface_id: "eni-87654321"),
    ]

    {
      image: "ami-005bdb005fb00e791",
      ssh_key_name: "ssh_key_name",
      connection_user: "user",
      connection_password: "password",
      network_interfaces: %w{eni-12345678 eni-87654321},
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @validation_key_url = "s3://bucket/foo/bar"
    @validation_key_file = "/tmp/a_good_temp_file"
    @validation_key_body = "TEST VALIDATION KEY\n"
    @vpc_id = "vpc-1a2b3c4d"
    @vpc_security_group_ids = ["sg-1a2b3c4d"]
  end

  describe "Spot Instance creation" do
    let(:spot_instance_server_def) do
      {
        instance_count: 1,
        launch_specification: server_attributes,
        spot_price: 0.001,
        type: "persistent",
      }
    end

    let(:spot_response) do
      OpenStruct.new(
        spot_instance_request_id: "sp-00653ds54543",
        instance_id: "i-00fe186450a2e8e97",
        type: "persistent",
        spot_price: 0.001
      )
    end

    before do
      knife_ec2_create.config[:spot_price] = 0.001
      knife_ec2_create.config[:spot_request_type] = "persistent"
      knife_ec2_create.config[:spot_wait_mode] = "prompt"
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:msg_pair)
      allow(knife_ec2_create).to receive(:print)
      allow(knife_ec2_create.ui).to receive(:color).and_return("")
      allow(knife_ec2_create).to receive(:confirm)
    end

    it "creates a new spot instance request with request type as persistent" do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:spot_instances_attributes).and_return(spot_instance_server_def)
      expect(ec2_connection).to receive(:request_spot_instances).with(spot_instance_server_def).and_return(spot_response)
      knife_ec2_create.config[:yes] = true
      allow(knife_ec2_create).to receive(:spot_instances_wait_until_ready).with("sp-00653ds54543").and_return(spot_response)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      knife_ec2_create.run
      expect(spot_response.type).to eq("persistent")
    end

    it "successfully creates a new spot instance" do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:spot_instances_attributes).and_return(spot_instance_server_def)
      expect(ec2_connection).to receive(:request_spot_instances).with(spot_instance_server_def).and_return(spot_response)
      knife_ec2_create.config[:yes] = true
      allow(knife_ec2_create).to receive(:spot_instances_wait_until_ready).with("sp-00653ds54543").and_return(spot_response)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      knife_ec2_create.run
    end

    it "does not create the spot instance request and creates a regular instance" do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      knife_ec2_create.config.delete(:spot_price)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      expect(ec2_connection).to receive(:run_instances).and_return(server_instances)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      knife_ec2_create.run
    end

    context "spot-wait-mode option" do
      before do
        allow(knife_ec2_create).to receive(:ami).and_return(ami)
        allow(knife_ec2_create).to receive(:validate_aws_config!)
        allow(knife_ec2_create).to receive(:validate_nics!)
      end
      context "when spot-price is not given" do
        context "spot-wait-mode option is not given" do
          before do
            knife_ec2_create.config.delete(:spot_price)
          end

          it "does not raise error" do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              "spot-wait-mode option requires that a spot-price option is set."
            )
            expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
          end
        end

        context "spot-wait-mode option is given" do
          before do
            knife_ec2_create.config.delete(:spot_price)
            knife_ec2_create.config[:spot_wait_mode] = "wait"
          end

          it "raises error" do
            expect(knife_ec2_create.ui).to receive(:error).with(
              "spot-wait-mode option requires that a spot-price option is set."
            )
            expect { knife_ec2_create.plugin_validate_options! }.to raise_error(SystemExit)
          end
        end
      end

      context "when spot-price is given" do
        context "spot-wait-mode option is not given" do
          before do
            knife_ec2_create.config[:spot_price] = 0.001
          end

          it "does not raise error" do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              "spot-wait-mode option requires that a spot-price option is set."
            )
            expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
          end
        end

        context "spot-wait-mode option is given" do
          before do
            knife_ec2_create.config[:spot_price] = 0.001
            knife_ec2_create.config[:spot_wait_mode] = "exit"
          end

          it "does not raise error" do
            expect(knife_ec2_create.ui).to_not receive(:error).with(
              "spot-wait-mode option requires that a spot-price option is set."
            )
            expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
          end
        end
      end
    end
  end

  describe "run" do
    before do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      knife_ec2_create.config[:yes] = true
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:msg_pair)
      @eip = "111.111.111.111"
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
      knife_ec2_create.config[:image] = "ami-005bdb005fb00e791"
    end

    it "creates an EC2 instance and bootstraps it" do
      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "creates an EC2 instance, assigns existing EIP and bootstraps it" do
      knife_ec2_create.config[:associate_eip] = @eip
      allow(ec2_server_attribs).to receive(:public_ip_address).and_return(@eip)
      expect(ec2_connection).to receive(:associate_address)

      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "creates an EC2 instance, enables ClassicLink and bootstraps it" do
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = @vpc_security_group_ids
      expect(ec2_connection).to receive(:attach_classic_link_vpc).with(instance_id: ec2_server_attribs[:id], groups: @vpc_security_group_ids, vpc_id: @vpc_id)
      knife_ec2_create.run
      expect(knife_ec2_create.server).to_not be_nil
    end

    it "retries if it receives Aws::EC2::Errors::Error" do
      expect(knife_ec2_create).to receive(:create_tags).and_raise(Aws::EC2::Errors::Error.new(self, "Default"))
      expect(knife_ec2_create).to receive(:create_tags).and_return(true)
      expect(knife_ec2_create).to receive(:sleep).and_return(true)
      expect(knife_ec2_create.ui).to receive(:warn).with(/retrying/)
      knife_ec2_create.run
    end

    it "actually writes to the validation key tempfile" do
      Chef::Config[:knife][:validation_key_url] = @validation_key_url
      knife_ec2_create.config[:validation_key_url] = @validation_key_url

      allow(knife_ec2_create).to receive_message_chain(:validation_key_tmpfile, :path).and_return(@validation_key_file)
      allow(Chef::Knife::S3Source).to receive(:fetch).with(@validation_key_url).and_return(@validation_key_body)
      expect(File).to receive(:open).with(@validation_key_file, "w")
      knife_ec2_create.run
    end
  end

  describe "run for EC2 Windows instance" do
    before do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:msg_pair)
      knife_ec2_create.config[:image] = "ami-005bdb005fb00e791"
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(true)
    end

    it "waits for EC2 to generate password if not supplied" do
      knife_ec2_create.config[:connection_protocol] = "winrm"
      knife_ec2_create.config[:connection_password] = nil
      expect(knife_ec2_create).to receive(:windows_password).and_return("")
      allow(knife_ec2_create).to receive(:check_windows_password_available).and_return(true)
      knife_ec2_create.run
    end
  end

  describe "when setting tags" do
    before do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:msg_pair)
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
    end

    it "sets the Name tag to the instance id by default" do
      tags_params = { tags: [ key: "Name", value: ec2_server_attribs.id], resources: [ec2_server_attribs.id] }
      expect(ec2_connection).to receive(:create_tags).with(tags_params)
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      knife_ec2_create.run
    end

    it "sets the Name tag to the chef_node_name when given" do
      knife_ec2_create.config[:chef_node_name] = "wombat"
      tags_params = { tags: [ key: "Name", value: "wombat"], resources: [ec2_server_attribs.id] }
      expect(ec2_connection).to receive(:create_tags).with(tags_params)
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      knife_ec2_create.run
    end

    it "sets the Name tag to the specified name when given --aws-tag Name=NAME" do
      knife_ec2_create.config[:aws_tag] = ["Name=bobcat"]
      tags_params = { tags: [ key: "Name", value: "bobcat"], resources: [ec2_server_attribs.id] }
      expect(ec2_connection).to receive(:create_tags).with(tags_params)
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      knife_ec2_create.run
    end

    it "sets arbitrary aws tags" do
      knife_ec2_create.config[:aws_tag] = ["foo=bar"]
      tags_params = { tags: [ { key: "foo", value: "bar" }, { key: "Name", value: "i-00fe186450a2e8e97" }], resources: [ec2_server_attribs.id] }
      expect(ec2_connection).to receive(:create_tags).with(tags_params)
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      knife_ec2_create.run
    end
  end

  describe "when setting volume tags" do
    before do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:msg_pair)
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
    end

    it "sets the volume tags as specified when given --volume-tags Key=Value" do
      knife_ec2_create.config[:volume_tags] = ["VolumeTagKey=TestVolumeTagValue"]
      tags_params = { tags: [ { key: "VolumeTagKey", value: "TestVolumeTagValue" }], resources: [ec2_server_attribs.volume_id] }
      allow(knife_ec2_create).to receive(:create_tags)
      expect(ec2_connection).to receive(:create_tags).with(tags_params)
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

    context "S3-based secret" do
      before(:each) do
        Chef::Config[:knife][:s3_secret] =
          "s3://test.bucket/folder/encrypted_data_bag_secret"
        @secret_content = "TEST DATA BAG SECRET\n"
        allow(knife_ec2_create).to receive(:s3_secret).and_return(@secret_content)
      end

      it "sets the secret to the expected test string" do
        expect(bootstrap.config[:secret]).to eql(@secret_content)
      end
    end
  end

  describe "S3 secret test cases" do
    before do
      Chef::Config[:knife][:s3_secret] =
        "s3://test.bucket/folder/encrypted_data_bag_secret"
      @secret_content = "TEST DATA BAG SECRET\n"
      allow(knife_ec2_create).to receive(:s3_secret).and_return(@secret_content)
    end

    context "when s3 secret option is passed" do
      it "sets the s3 secret value to cl_secret key" do
        knife_ec2_create.bootstrap_common_params
        expect(Chef::Config[:knife][:cl_secret]).to eql(@secret_content)
      end
    end

    context "when s3 secret option is not passed" do
      it "sets the cl_secret value to nil" do
        Chef::Config[:knife].delete(:s3_secret)
        Chef::Config[:knife].delete(:cl_secret)
        knife_ec2_create.bootstrap_common_params
        expect(Chef::Config[:knife][:cl_secret]).to eql(nil)
      end
    end
  end

  context "when deprecated aws_ssh_key_id option is used in knife config and no ssh-key is supplied on the CLI" do
    before do
      Chef::Config[:knife][:aws_ssh_key_id] = "ssh_key_name"
      Chef::Config[:knife].delete(:ssh_key_name)
      @aws_key = Chef::Config[:knife][:aws_ssh_key_id]
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
    end

    it "gives warning message and creates the attribute with the required name" do
      expect(knife_ec2_create.ui).to receive(:warn).with("Use of aws_ssh_key_id option in knife.rb/config.rb config is deprecated, use ssh_key_name option instead.")
      knife_ec2_create.plugin_validate_options!
      expect(Chef::Config[:knife][:ssh_key_name]).to eq(@aws_key)
    end
  end

  context "when deprecated aws_ssh_key_id option is used in knife config but ssh-key is also supplied on the CLI" do
    before do
      Chef::Config[:knife][:aws_ssh_key_id] = "ssh_key_name"
      @aws_key = Chef::Config[:knife][:aws_ssh_key_id]
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
    end

    it "gives warning message and gives preference to CLI value over knife config's value" do
      expect(knife_ec2_create.ui).to receive(:warn).with("Use of aws_ssh_key_id option in knife.rb/config.rb config is deprecated, use ssh_key_name option instead.")
      knife_ec2_create.plugin_validate_options!
      expect(Chef::Config[:knife][:ssh_key_name]).to eq(@aws_key)
    end
  end

  context "when ssh_key_name option is used in knife config instead of deprecated aws_ssh_key_id option" do
    before do
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
    end

    it "does nothing" do
      knife_ec2_create.plugin_validate_options!
    end
  end

  context "when ssh_key_name option is used in knife config also it is passed on the CLI" do
    before do
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
    end

    it "ssh-key passed over CLI gets preference over knife config value" do
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      server_def = knife_ec2_create.fetch_ec2_instance("i-00fe186450a2e8e97")
      expect(server_def.key_name).to eq(knife_ec2_create.config[:ssh_key_name])
    end
  end

  describe "when configuring the bootstrap process" do
    before do
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(false)
      allow(knife_ec2_create).to receive(:tunnel_test_ssh).and_return(true)
      allow(knife_ec2_create).to receive(:wait_for_tunnelled_sshd).and_return(true)
      knife_ec2_create.config[:connection_user] = "ubuntu"
      knife_ec2_create.config[:ssh_identity_file] = "~/.ssh/aws-key.pem"
      knife_ec2_create.config[:connection_protocol] = "ssh"
      knife_ec2_create.config[:connection_port] = 22
      knife_ec2_create.config[:ssh_gateway] = "bastion.host.com"
      knife_ec2_create.config[:chef_node_name] = "blarf"
      knife_ec2_create.config[:run_list] = ["role[base]"]
      knife_ec2_create.config[:use_sudo] = true
      knife_ec2_create.config[:first_boot_attributes] = "{'my_attributes':{'foo':'bar'}"
      knife_ec2_create.config[:first_boot_attributes_from_file] = "{'my_attributes':{'foo':'bar'}"
      knife_ec2_create.plugin_create_instance!
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server" do
      expect(knife_ec2_create.name_args).to eq(["ec2-75.101.253.10.compute-1.amazonaws.com"])
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      expect(knife_ec2_create.config[:first_boot_attributes]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "should set the bootstrap 'first_boot_attributes_from_file' correctly" do
      expect(knife_ec2_create.config[:first_boot_attributes_from_file]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "configures sets the bootstrap's run_list" do
      expect(knife_ec2_create.config[:run_list]).to eq(["role[base]"])
    end

    it "configures the bootstrap to use the correct connection_user login" do
      expect(knife_ec2_create.config[:connection_user]).to eq("ubuntu")
    end

    it "configures the bootstrap to use the correct ssh_gateway host" do
      expect(knife_ec2_create.config[:ssh_gateway]).to eq("bastion.host.com")
    end

    it "configures the bootstrap to use the correct ssh identity file" do
      expect(knife_ec2_create.config[:ssh_identity_file]).to eq("~/.ssh/aws-key.pem")
    end

    it "configures the bootstrap to use the correct connection_port number" do
      expect(knife_ec2_create.config[:connection_port]).to eq(22)
    end

    it "configures the bootstrap to use sudo" do
      expect(knife_ec2_create.config[:use_sudo]).to eq(true)
    end

    it "configured the bootstrap to set an ec2 hint (via Chef::Config)" do
      expect(Chef::Config[:knife][:hints]["ec2"]).not_to be_nil
    end
  end

  describe "when configuring chef node name for the bootstrap process" do
    before do
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
    end
    it "configures the bootstrap to use the configured node name if provided" do
      knife_ec2_create.config[:chef_node_name] = "blarf"
      knife_ec2_create.plugin_create_instance!
      expect(knife_ec2_create.config[:chef_node_name]).to eq("blarf")
    end

    it "configures the bootstrap to use the EC2 server id if no explicit node name is set" do
      knife_ec2_create.config[:chef_node_name] = nil
      knife_ec2_create.plugin_create_instance!
      expect(knife_ec2_create.config[:chef_node_name]).to eq(ec2_server_attribs.id)
    end
  end

  describe "when configuring the ssh bootstrap process for windows" do
    before do
      knife_ec2_create.config[:connection_user] = "administrator"
      knife_ec2_create.config[:connection_password] = "password"
      knife_ec2_create.config[:connection_port] = 22
      knife_ec2_create.config[:forward_agent] = true
      knife_ec2_create.config[:connection_protocol] = "ssh"
      knife_ec2_create.config[:image] = "ami-005bdb005fb00e791"
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
      allow(knife_ec2_create).to receive(:is_image_windows?).and_return(true)
    end

    it "sets the bootstrap 'forward_agent' correctly" do
      knife_ec2_create.plugin_validate_options!
      expect(knife_ec2_create.config[:forward_agent]).to eq(true)
    end
  end

  describe "when configuring the winrm bootstrap process for windows" do
    before do
      knife_ec2_create.config[:connection_user] = "Administrator"
      knife_ec2_create.config[:connection_password] = "password"
      knife_ec2_create.config[:connection_port] = 12345
      knife_ec2_create.config[:winrm_ssl] = true
      knife_ec2_create.config[:kerberos_realm] = "realm"
      knife_ec2_create.config[:kerberos_service] = "service"
      knife_ec2_create.config[:chef_node_name] = "blarf"
      knife_ec2_create.config[:run_list] = ["role[base]"]
      knife_ec2_create.config[:first_boot_attributes] = "{'my_attributes':{'foo':'bar'}"
      knife_ec2_create.config[:msi_url] = "https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi"
      knife_ec2_create.config[:install_as_service] = true
      knife_ec2_create.config[:session_timeout] = "90"
      knife_ec2_create.config[:fqdn] = "ec2-75.101.253.10.compute-1.amazonaws.com"

      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
      allow(knife_ec2_create).to receive(:msg_pair)
      allow(knife_ec2_create).to receive(:puts)
      allow(knife_ec2_create).to receive(:print)
      allow(knife_ec2_create).to receive(:fetch_server_fqdn)
      knife_ec2_create.plugin_create_instance!
    end

    it "should set the winrm username correctly" do
      expect(knife_ec2_create.config[:connection_user]).to eq("Administrator")
    end

    it "should set the winrm password correctly" do
      expect(knife_ec2_create.config[:connection_password]).to eq("password")
    end

    it "should set the winrm port correctly" do
      expect(knife_ec2_create.config[:connection_port]).to eq(12345)
    end

    it "should set the winrm transport layer correctly" do
      expect(knife_ec2_create.config[:winrm_ssl]).to eq(true)
    end

    it "should set the kerberos realm correctly" do
      expect(knife_ec2_create.config[:kerberos_realm]).to eq("realm")
    end

    it "should set the kerberos service correctly" do
      expect(knife_ec2_create.config[:kerberos_service]).to eq("service")
    end

    it "should set the bootstrap 'name argument' to the Windows/AD hostname of the EC2 server" do
      expect(knife_ec2_create.name_args).to eq(["ec2-75.101.253.10.compute-1.amazonaws.com"])
    end

    it "should set the bootstrap 'name argument' to the hostname of the EC2 server when AD/Kerberos is not used" do
      knife_ec2_create.config[:kerberos_realm] = nil
      expect(knife_ec2_create.name_args).to eq(["ec2-75.101.253.10.compute-1.amazonaws.com"])
    end

    it "should set the bootstrap 'first_boot_attributes' correctly" do
      expect(knife_ec2_create.config[:first_boot_attributes]).to eq("{'my_attributes':{'foo':'bar'}")
    end

    it "should set the bootstrap 'msi_url' correctly" do
      expect(knife_ec2_create.config[:msi_url]).to eq("https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-client-12.3.0-1.msi")
    end

    it "should set the bootstrap 'install_as_service' correctly" do
      expect(knife_ec2_create.config[:install_as_service]).to eq(true)
    end

    it "should set the bootstrap 'session_timeout' correctly" do
      expect(knife_ec2_create.config[:session_timeout].to_i).to eq(90)
    end

    it "configures sets the bootstrap's run_list" do
      expect(knife_ec2_create.config[:run_list]).to eq(["role[base]"])
    end

    it "configures aws_connection_timeout for bootstrap to default to 10 minutes" do
      expect(knife_ec2_create.options[:aws_connection_timeout][:default]).to eq(600)
    end
  end

  describe "when validating the command-line parameters" do
    before do
      allow(knife_ec2_create.ui).to receive(:error)
      allow(knife_ec2_create.ui).to receive(:msg)
    end

    describe "when reading aws_credential_file" do
      before do
        Chef::Config[:knife].delete(:aws_access_key_id)
        Chef::Config[:knife].delete(:aws_secret_access_key)

        allow(File).to receive(:exist?).with("/apple/pear").and_return(true)
        Chef::Config[:knife][:aws_credential_file] = "/apple/pear"
        @access_key_id = "access_key_id"
        @secret_key = "secret_key"
      end

      it "reads UNIX Line endings" do
        allow(File).to receive(:read)
          .and_return("AWSAccessKeyId=#{@access_key_id}\nAWSSecretKey=#{@secret_key}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "reads DOS Line endings" do
        allow(File).to receive(:read)
          .and_return("AWSAccessKeyId=#{@access_key_id}\r\nAWSSecretKey=#{@secret_key}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "reads UNIX Line endings for new format" do
        Chef::Config[:knife][:aws_profile] = "default"
        allow(File).to receive(:read)
          .and_return("[default]\naws_access_key_id=#{@access_key_id}\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "reads DOS Line endings for new format" do
        Chef::Config[:knife][:aws_profile] = "default"
        allow(File).to receive(:read)
          .and_return("[default]\naws_access_key_id=#{@access_key_id}\r\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      it "loads the correct profile" do
        Chef::Config[:knife][:aws_profile] = "other"
        allow(File).to receive(:read)
          .and_return("[default]\naws_access_key_id=TESTKEY\r\naws_secret_access_key=TESTSECRET\n\n[other]\naws_access_key_id=#{@access_key_id}\r\naws_secret_access_key=#{@secret_key}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:aws_access_key_id]).to eq(@access_key_id)
        expect(Chef::Config[:knife][:aws_secret_access_key]).to eq(@secret_key)
      end

      context "when invalid --aws-profile is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_profile] = "xyz"
          allow(File).to receive(:read).and_return("[default]\naws_access_key_id=TESTKEY\r\naws_secret_access_key=TESTSECRET")
          expect { knife_ec2_create.validate_aws_config! }.to raise_error("The provided --aws-profile 'xyz' is invalid. Does the credential file at '/apple/pear' contain this profile?")
        end
      end

      context "when non-existent --aws_credential_file is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_credential_file] = "/foo/bar"
          allow(File).to receive(:exist?).and_return(false)
          expect { knife_ec2_create.validate_aws_config! }.to raise_error("The provided --aws_credential_file (/foo/bar) cannot be found on disk.")
        end
      end
    end

    describe "when reading aws_config_file" do
      before do
        Chef::Config[:knife][:aws_config_file] = "/apple/pear"
        Chef::Config[:knife][:aws_access_key_id] = "aws_access_key_id"
        Chef::Config[:knife][:aws_secret_access_key] = "aws_secret_access_key"

        allow(File).to receive(:exist?).and_return(true)
        allow(knife_ec2_create).to receive(:aws_cred_file_location).and_return(nil)
        @region = "region"
      end

      it "reads UNIX Line endings" do
        allow(File).to receive(:read)
          .and_return("[default]\r\nregion=#{@region}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "reads DOS Line endings" do
        allow(File).to receive(:read)
          .and_return("[default]\r\nregion=#{@region}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "reads UNIX Line endings for new format" do
        allow(File).to receive(:read)
          .and_return("[default]\nregion=#{@region}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "reads DOS Line endings for new format" do
        allow(File).to receive(:read)
          .and_return("[default]\nregion=#{@region}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      it "loads the correct profile" do
        Chef::Config[:knife][:aws_profile] = "other"
        allow(File).to receive(:read)
          .and_return("[default]\nregion=TESTREGION\n\n[profile other]\nregion=#{@region}")
        knife_ec2_create.validate_aws_config!
        expect(Chef::Config[:knife][:region]).to eq(@region)
      end

      context "when invalid --aws-profile is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_profile] = "xyz"
          allow(File).to receive(:read).and_return("[default]\nregion=TESTREGION")
          expect { knife_ec2_create.validate_aws_config! }.to raise_error("The provided --aws-profile 'profile xyz' is invalid.")
        end
      end

      context "when non-existent --aws_config_file is given" do
        it "raises exception" do
          Chef::Config[:knife][:aws_config_file] = "/foo/bar"
          allow(File).to receive(:exist?).and_return(false)
          expect { knife_ec2_create.validate_aws_config! }.to raise_error("The provided --aws_config_file (/foo/bar) cannot be found on disk.")
        end
      end

      context "when aws_profile is passed a 'default' from CLI or knife.rb file" do
        it "loads the default profile successfully" do
          Chef::Config[:knife][:aws_profile] = "default"
          allow(File).to receive(:read).and_return("[default]\nregion=#{@region}\n\n[profile other]\nregion=TESTREGION")
          knife_ec2_create.validate_aws_config!
          expect(Chef::Config[:knife][:region]).to eq(@region)
        end
      end
    end

    it "understands that file:// validation key URIs are just paths" do
      Chef::Config[:knife][:validation_key_url] = "file:///foo/bar"
      expect(knife_ec2_create.validation_key_path).to eq("/foo/bar")
    end

    it "returns a path to a tmp file when presented with a URI for the " \
      "validation key" do
        Chef::Config[:knife][:validation_key_url] = @validation_key_url

        allow(knife_ec2_create).to receive_message_chain(:validation_key_tmpfile, :path).and_return(@validation_key_file)

        expect(knife_ec2_create.validation_key_path).to eq(@validation_key_file)
      end

    it "disallows security group names when using a VPC" do
      knife_ec2_create.config[:subnet_id] = @subnet_1_id
      knife_ec2_create.config[:security_group_ids] = "sg-aabbccdd"
      knife_ec2_create.config[:security_groups] = "groupname"

      allow(ec2_connection).to receive_message_chain(:subnets, :get).with(@subnet_1_id).and_return(@subnet_1)

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error(SystemExit)
    end

    it "disallows invalid network interface ids" do
      knife_ec2_create.config[:network_interfaces] = ["INVALID_ID"]

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error(SystemExit)
    end

    it "disallows network interfaces not in the right VPC" do
      knife_ec2_create.config[:subnet_id] = @subnet_1_id
      knife_ec2_create.config[:security_group_ids] = "sg-aabbccdd"
      knife_ec2_create.config[:security_groups] = "groupname"

      allow(ec2_connection).to receive_message_chain(:subnets, :get).with(@subnet_1_id).and_return(@subnet_1)

      allow(ec2_connection).to receive_message_chain(:network_interfaces, :all).and_return [
        double("network_interfaces", network_interface_id: "eni-12345678", vpc_id: "another_vpc"),
        double("network_interfaces", network_interface_id: "eni-87654321", vpc_id: my_vpc),
      ]

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows private ips when not using a VPC" do
      knife_ec2_create.config[:private_ip_address] = "10.0.0.10"

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows specifying credentials file and aws keys" do
      Chef::Config[:knife][:aws_credential_file] = "/apple/pear"
      allow(File).to receive(:exist?).with("/apple/pear").and_return(true)
      allow(File).to receive(:read).and_return("AWSAccessKeyId=b\nAWSSecretKey=a")

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows associate public ip option when not using a VPC" do
      knife_ec2_create.config[:associate_public_ip] = true
      knife_ec2_create.config[:subnet_id] = nil

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows setting only one of the two ClassicLink options" do
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = nil

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows ClassicLink with VPC" do
      knife_ec2_create.config[:subnet_id] = "subnet-1a2b3c4d"
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      knife_ec2_create.config[:classic_link_vpc_security_group_ids] = @vpc_security_group_ids

      allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows ebs provisioned iops option when not using ebs volume type" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = nil

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows ebs provisioned iops option when not using ebs volume type 'io1'" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = "standard"

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows ebs volume type if its other than 'io1' or 'gp2' or 'standard'" do
      knife_ec2_create.config[:ebs_provisioned_iops] = "123"
      knife_ec2_create.config[:ebs_volume_type] = "invalid"

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    it "disallows 'io1' ebs volume type when not using ebs provisioned iops" do
      knife_ec2_create.config[:ebs_provisioned_iops] = nil
      knife_ec2_create.config[:ebs_volume_type] = "io1"

      expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
    end

    context "when ebs_encrypted option specified" do
      before do
        allow(knife_ec2_create).to receive(:ami).and_return(ami)
        allow(knife_ec2_create).to receive(:validate_aws_config!)
        allow(knife_ec2_create).to receive(:validate_nics!).and_return(true)
      end
      it "not raise any validation error if valid ebs_size specified" do
        knife_ec2_create.config[:ebs_size] = "8"
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to_not receive(:error).with(" --ebs-encrypted option requires valid --ebs-size to be specified.")
        knife_ec2_create.plugin_validate_options!
      end

      it "raise error on missing ebs_size" do
        knife_ec2_create.config[:ebs_size] = nil
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-encrypted option requires valid --ebs-size to be specified.")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end

      it "raise error if invalid ebs_size specified for 'standard' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "1055"
        knife_ec2_create.config[:ebs_volume_type] = "standard"
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 1-1024 for 'standard' ebs volume type.")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end

      it "raise error on invalid ebs_size specified for 'gp2' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "16500"
        knife_ec2_create.config[:ebs_volume_type] = "gp2"
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 1-16384 for 'gp2' ebs volume type.")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end

      it "raise error on invalid ebs_size specified for 'io1' VolumeType" do
        knife_ec2_create.config[:ebs_size] = "3"
        knife_ec2_create.config[:ebs_provisioned_iops] = "200"
        knife_ec2_create.config[:ebs_volume_type] = "io1"
        knife_ec2_create.config[:flavor] = "m3.medium"
        knife_ec2_create.config[:ebs_encrypted] = true
        expect(knife_ec2_create.ui).to receive(:error).with(" --ebs-size should be in between 4-16384 for 'io1' ebs volume type.")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end
    end

    context "when cpu_credits option is specified" do
      it "raise error on missing flavor" do
        knife_ec2_create.config[:cpu_credits] = "unlimited"
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end

      it "raise error when invalid string is passed other than 'unlimited' and 'standard'" do
        knife_ec2_create.config[:cpu_credits] = "xyz"
        knife_ec2_create.config[:flavor] = "t2.medium"
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end

      it "raise error on flavor type other than T2/T3" do
        knife_ec2_create.config[:cpu_credits] = "unlimited"
        knife_ec2_create.config[:flavor] = "m3.medium"
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error SystemExit
      end
    end
  end

  describe "when creating the server definition" do
    before do
      allow(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
    end

    it "sets the specified placement_group" do
      knife_ec2_create.config[:placement_group] = "some_placement_group"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:placement][:group_name]).to eq("some_placement_group")
    end

    it "sets the specified security group names" do
      knife_ec2_create.config[:security_groups] = ["groupname"]
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:groups]).to eq(["groupname"])
    end

    it "sets the specified security group ids" do
      knife_ec2_create.config[:security_group_ids] = ["sg-00aa11bb"]
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:security_group_ids]).to eq(["sg-00aa11bb"])
    end

    it "sets the image id from CLI arguments over knife config" do
      knife_ec2_create.config[:image] = "ami-005bdb005fb00e791"
      Chef::Config[:knife][:image] = "ami-54354"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:image_id]).to eq("ami-005bdb005fb00e791")
    end

    it "sets the flavor id from CLI arguments over knife config" do
      knife_ec2_create.config[:flavor] = "m1.small"
      Chef::Config[:knife][:flavor] = "bitty"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:instance_type]).to eq("m1.small")
    end

    it "sets the availability zone from CLI arguments over knife config" do
      knife_ec2_create.config[:availability_zone] = "us-west-2a"
      Chef::Config[:knife][:availability_zone] = "dat-one"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:placement][:availability_zone]).to eq("us-west-2a")
    end

    it "adds the specified ephemeral device mappings" do
      knife_ec2_create.config[:ephemeral] = [ "/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde" ]
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:block_device_mappings]).to eq([{ device_name: nil, ebs: { delete_on_termination: nil, iops: "123", volume_size: "30", volume_type: nil } },
                                                   { virtual_name: "ephemeral0", device_name: "/dev/sdb", ebs: { volume_size: "30" } },
                                                   { virtual_name: "ephemeral1", device_name: "/dev/sdc", ebs: { volume_size: "30" } },
                                                   { virtual_name: "ephemeral2", device_name: "/dev/sdd", ebs: { volume_size: "30" } },
                                                   { virtual_name: "ephemeral3", device_name: "/dev/sde", ebs: { volume_size: "30" } }])
    end

    it "sets the specified private ip address" do
      knife_ec2_create.config[:subnet_id] = "subnet-1a2b3c4d"
      knife_ec2_create.config[:private_ip_address] = "10.0.0.10"
      server_def = knife_ec2_create.server_attributes

      expect(server_def[:network_interfaces][0][:subnet_id]).to eq("subnet-1a2b3c4d")
      expect(server_def[:network_interfaces][0][:private_ip_address]).to eq("10.0.0.10")
    end

    it "sets the IAM server role when one is specified" do
      knife_ec2_create.config[:iam_instance_profile] = ["iam-role"]
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:iam_instance_profile][:name]).to eq(["iam-role"])
    end

    it "doesn't set an IAM server role by default" do
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:iam_instance_profile][:name]).to eq(nil)
    end

    it "doesn't use IAM profile by default" do
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:use_iam_profile]).to eq(nil)
    end

    it "Set Tenancy Dedicated when both VPC mode and Flag is True" do
      knife_ec2_create.config[:dedicated_instance] = true
      allow(knife_ec2_create).to receive_messages(vpc_mode?: true)
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:placement][:tenancy]).to eq("dedicated")
    end

    it "Tenancy should be default with no vpc mode even is specified" do
      knife_ec2_create.config[:dedicated_instance] = true
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:placement][:tenancy]).to eq(nil)
    end

    it "Tenancy should be default with vpc but not requested" do
      allow(knife_ec2_create).to receive_messages(vpc_mode?: true)
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:placement][:tenancy]).to eq(nil)
    end

    it "sets associate_public_ip to true if specified and in vpc_mode" do
      knife_ec2_create.config[:subnet_id] = "subnet-1a2b3c4d"
      knife_ec2_create.config[:associate_public_ip] = true
      server_def = knife_ec2_create.server_attributes

      expect(server_def[:network_interfaces][0][:subnet_id]).to eq("subnet-1a2b3c4d")
      expect(server_def[:network_interfaces][0][:associate_public_ip_address]).to eq(true)
    end

    it "sets the spot price" do
      knife_ec2_create.config[:spot_price] = "1.99"
      server_def = knife_ec2_create.spot_instances_attributes
      expect(server_def[:spot_price]).to eq("1.99")
    end

    it "sets the spot instance request type as persistent" do
      knife_ec2_create.config[:spot_request_type] = "persistent"
      server_def = knife_ec2_create.spot_instances_attributes
      expect(server_def[:type]).to eq("persistent")
    end

    it "sets the spot instance request type as one-time" do
      knife_ec2_create.config[:spot_request_type] = "one-time"
      server_def = knife_ec2_create.spot_instances_attributes
      expect(server_def[:type]).to eq("one-time")
    end

    it "sets cpu credit as unlimited for T2 instance" do
      knife_ec2_create.config[:cpu_credits] = "unlimited"
      knife_ec2_create.config[:flavor] = "t2.micro"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:credit_specification][:cpu_credits]).to eq("unlimited")
    end

    it "sets cpu credit as standard for T3 instance" do
      knife_ec2_create.config[:cpu_credits] = "standard"
      knife_ec2_create.config[:flavor] = "t3.micro"
      server_def = knife_ec2_create.server_attributes
      expect(server_def[:credit_specification][:cpu_credits]).to eq("standard")
    end

    context "when using ebs volume type and ebs provisioned iops rate options" do
      before do
        allow(knife_ec2_create).to receive(:ami).and_return(ami)
        allow(knife_ec2_create).to receive(:msg)
        allow(knife_ec2_create).to receive(:puts)
      end

      it "sets the specified 'standard' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = "standard"
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:block_device_mappings].first[:ebs][:volume_type]).to eq("standard")
      end

      it "sets the specified 'io1' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = "io1"
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:block_device_mappings].first[:ebs][:volume_type]).to eq("io1")
      end

      it "sets the specified 'gp2' ebs volume type" do
        knife_ec2_create.config[:ebs_volume_type] = "gp2"
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:block_device_mappings].first[:ebs][:volume_type]).to eq("gp2")
      end

      it "sets the specified ebs provisioned iops rate" do
        knife_ec2_create.config[:ebs_provisioned_iops] = "1234"
        knife_ec2_create.config[:ebs_volume_type] = "io1"
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:block_device_mappings].first[:ebs][:iops]).to eq("1234")
      end

      it "disallows non integer ebs provisioned iops rate" do
        knife_ec2_create.config[:ebs_provisioned_iops] = "123abcd"
        expect { knife_ec2_create.server_attributes }.to raise_error SystemExit
      end

      it "sets the iops rate from ami" do
        knife_ec2_create.config[:ebs_volume_type] = "io1"
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:block_device_mappings].first[:ebs][:iops]).to eq("123")
      end
    end
  end

  describe "wait_for_sshd" do
    let(:gateway) { "test.gateway.com" }
    let(:hostname) { "test.host.com" }

    it "should wait for tunnelled ssh if a ssh gateway is provided" do
      allow(knife_ec2_create).to receive(:get_ssh_gateway_for).and_return(gateway)
      expect(knife_ec2_create).to receive(:wait_for_tunnelled_sshd).with(gateway, hostname)
      knife_ec2_create.wait_for_sshd(hostname)
    end

    it "should wait for direct ssh if a ssh gateway is not provided" do
      allow(knife_ec2_create).to receive(:get_ssh_gateway_for).and_return(nil)
      knife_ec2_create.config[:connection_port] = 22
      knife_ec2_create.config[:connection_protocol] = "ssh"
      expect(knife_ec2_create).to receive(:wait_for_direct_sshd).with(hostname, 22)
      knife_ec2_create.wait_for_sshd(hostname)
    end
  end

  describe "get_ssh_gateway_for" do
    let(:gateway) { "test.gateway.com" }
    let(:hostname) { "test.host.com" }

    it "should give precedence to the ssh gateway specified in the knife configuration" do
      allow(Net::SSH::Config).to receive(:for).and_return(proxy: Net::SSH::Proxy::Command.new("ssh some.other.gateway.com nc %h %p"))
      knife_ec2_create.config[:ssh_gateway] = gateway
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to eq(gateway)
    end

    it "should return the ssh gateway specified in the ssh configuration even if the config option is not set" do
      # This should already be false, but test this explicitly for regression
      knife_ec2_create.config[:ssh_gateway] = false
      allow(Net::SSH::Config).to receive(:for).and_return(proxy: Net::SSH::Proxy::Command.new("ssh #{gateway} nc %h %p"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to eq(gateway)
    end

    it "should return nil if the ssh gateway cannot be parsed from the ssh proxy command" do
      allow(Net::SSH::Config).to receive(:for).and_return(proxy: Net::SSH::Proxy::Command.new("cannot parse host"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

    it "should return nil if the ssh proxy is not a proxy command" do
      allow(Net::SSH::Config).to receive(:for).and_return(proxy: Net::SSH::Proxy::HTTP.new("httphost.com"))
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

    it "returns nil if the ssh config has no proxy" do
      allow(Net::SSH::Config).to receive(:for).and_return(user: "darius")
      expect(knife_ec2_create.get_ssh_gateway_for(hostname)).to be_nil
    end

  end

  describe "#subnet_public_ip_on_launch?" do
    let(:subnet_res) do
      OpenStruct.new(
        availability_zone: "us-west-2a",
        map_public_ip_on_launch: false,
        subnet_id: "subnet-1a2b3c4d"
      )
    end
    let(:subnets) { OpenStruct.new(subnets: [subnet_res]) }

    before do
      allow(ec2_connection).to receive(:describe_subnets).and_return(subnets)
      allow(knife_ec2_create).to receive_message_chain(:server, :subnet_id).and_return("subnet-1a2b3c4d")
    end

    context "when auto_assign_public_ip is enabled" do
      it "returns true" do
        allow(knife_ec2_create).to receive(:fetch_subnet).with("subnet-1a2b3c4d").and_return double( map_public_ip_on_launch: true )
        expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(true)
      end
    end

    context "when auto_assign_public_ip is disabled" do
      it "returns false" do
        expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(false)
      end
    end
  end

  describe "#reload_server_data_required?" do
    it "returns true if associate_eip is set" do
      knife_ec2_create.config[:associate_eip] = "10.0.0.1"
      expect(knife_ec2_create.reload_server_data_required?).to eq(true)
    end

    it "returns true if classic_link_vpc_id is set" do
      knife_ec2_create.config[:classic_link_vpc_id] = @vpc_id
      expect(knife_ec2_create.reload_server_data_required?).to eq(true)
    end

    it "returns true if network_interfaces is set" do
      knife_ec2_create.config[:network_interfaces] = %w{eni-12345678 eni-87654321}
      expect(knife_ec2_create.reload_server_data_required?).to eq(true)
    end

    it "returns false if associate_eip, classic_link_vpc_id, network_interfaces are not set" do
      knife_ec2_create.config[:associate_eip] = nil
      knife_ec2_create.config[:classic_link_vpc_id] = nil
      knife_ec2_create.config[:network_interfaces] = nil
      expect(knife_ec2_create.reload_server_data_required?).to eq(false)
    end
  end

  describe "ssh_connect_host" do
    let(:new_ec2_server) { double }

    before(:each) do
      allow(knife_ec2_create).to receive(:fetch_ec2_instance).and_return(new_ec2_server)
      allow(new_ec2_server).to receive_messages(
        public_dns_name: "public.example.org",
        private_ip_address: "192.168.1.100",
        custom: "custom",
        public_ip_address: "111.111.111.111",
        subnet_id: "subnet-1a2b3c4d"
      )
      allow(knife_ec2_create).to receive_messages(server: new_ec2_server)
    end

    describe "by default" do
      it "should use public dns name" do
        expect(knife_ec2_create.connection_host).to eq("public.example.org")
      end
    end

    describe "when dns name not exist" do
      it "should use public_ip_address " do
        allow(new_ec2_server).to receive(:public_dns_name).and_return(nil)
        expect(knife_ec2_create.connection_host).to eq("111.111.111.111")
      end
    end

    context "when vpc_mode? is true" do
      before do
        allow(knife_ec2_create).to receive_messages(vpc_mode?: true)
      end

      context "subnet_public_ip_on_launch? is true" do
        it "uses the dns_name or public_ip_address" do
          allow(knife_ec2_create).to receive(:fetch_subnet).and_return double( map_public_ip_on_launch: true )
          expect(knife_ec2_create.subnet_public_ip_on_launch?).to eq(true)
          expect(knife_ec2_create.connection_host).to eq("public.example.org")
        end
      end

      context "--associate-public-ip is specified" do
        it "uses the dns_name or public_ip_address" do
          knife_ec2_create.config[:associate_public_ip] = true
          allow(knife_ec2_create).to receive(:fetch_subnet).and_return double( map_public_ip_on_launch: false )
          expect(knife_ec2_create.connection_host).to eq("public.example.org")
        end
      end

      context "--associate-eip is specified" do
        it "uses the dns_name or public_ip_address" do
          knife_ec2_create.config[:associate_eip] = "111.111.111.111"
          allow(knife_ec2_create).to receive(:fetch_subnet).and_return double( map_public_ip_on_launch: false )
          expect(knife_ec2_create.connection_host).to eq("public.example.org")
        end
      end

      context "with no other ip flags" do
        it "uses private_ip_address" do
          allow(knife_ec2_create).to receive(:fetch_subnet).and_return double( map_public_ip_on_launch: false )
          expect(knife_ec2_create.connection_host).to eq("192.168.1.100")
        end
      end
    end

    describe "with custom server attribute" do
      it "should use custom server attribute" do
        knife_ec2_create.config[:server_connect_attribute] = "custom"
        expect(knife_ec2_create.connection_host).to eq("custom")
      end
    end
  end

  describe "tunnel_test_ssh" do
    let(:gateway_host) { "test.gateway.com" }
    let(:gateway) { double("gateway") }
    let(:hostname) { "test.host.com" }
    let(:local_port) { 23 }

    before(:each) do
      allow(knife_ec2_create).to receive(:configure_ssh_gateway).and_return(gateway)
    end

    it "should test ssh through a gateway" do
      knife_ec2_create.config[:connection_port] = 22
      expect(gateway).to receive(:open).with(hostname, 22).and_yield(local_port)
      expect(knife_ec2_create).to receive(:tcp_test_ssh).with("localhost", local_port).and_return(true)
      expect(knife_ec2_create.tunnel_test_ssh(gateway_host, hostname)).to eq(true)
    end
  end

  describe "configure_ssh_gateway" do
    let(:gateway_host) { "test.gateway.com" }
    let(:gateway_user) { "gateway_user" }

    it "configures a ssh gateway with no user and the default port when the SSH Config is empty" do
      allow(Net::SSH::Config).to receive(:for).and_return({})
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, port: 22)
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures a ssh gateway with the user specified in the SSH Config" do
      allow(Net::SSH::Config).to receive(:for).and_return({ user: gateway_user })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, gateway_user, port: 22)
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures a ssh gateway with the user specified in the ssh gateway string" do
      allow(Net::SSH::Config).to receive(:for).and_return({ user: gateway_user })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, "override_user", port: 22)
      knife_ec2_create.configure_ssh_gateway("override_user@#{gateway_host}")
    end

    it "configures a ssh gateway with the port specified in the ssh gateway string" do
      allow(Net::SSH::Config).to receive(:for).and_return({})
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, port: "24")
      knife_ec2_create.configure_ssh_gateway("#{gateway_host}:24")
    end

    it "configures a ssh gateway with the keys specified in the SSH Config" do
      allow(Net::SSH::Config).to receive(:for).and_return({ keys: ["configuredkey"] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, port: 22, keys: ["configuredkey"])
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "configures the ssh gateway with the key specified on the knife config / command line" do
      knife_ec2_create.config[:ssh_gateway_identity] = "/home/fireman/.ssh/gateway.pem"
      # Net::SSH::Config.stub(:for).and_return({ :keys => ['configuredkey'] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, port: 22, keys: ["/home/fireman/.ssh/gateway.pem"])
      knife_ec2_create.configure_ssh_gateway(gateway_host)
    end

    it "prefers the knife config over the ssh config for the gateway keys" do
      knife_ec2_create.config[:ssh_gateway_identity] = "/home/fireman/.ssh/gateway.pem"
      allow(Net::SSH::Config).to receive(:for).and_return({ keys: ["not_this_key_dude"] })
      expect(Net::SSH::Gateway).to receive(:new).with(gateway_host, nil, port: 22, keys: ["/home/fireman/.ssh/gateway.pem"])
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
      knife_ec2_create.tcp_test_ssh("blackhole.ninja", 22) { nil }
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

  describe "ssl_config_user_data" do
    before do
      knife_ec2_create.config[:connection_password] = "ec2@123"
    end

    context "For domain user" do
      before do
        knife_ec2_create.config[:connection_user] = "domain\\ec2"
        @ssl_config_data = <<~EOH

          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
        EOH
      end

      it "gets ssl config user data" do
        expect(knife_ec2_create.ssl_config_user_data).to be == @ssl_config_data
      end
    end

    context "For local user" do
      before do
        knife_ec2_create.config[:connection_user] = ".\\ec2"
        @ssl_config_data = <<~EOH
          net user /add ec2 ec2@123 ;
          net localgroup Administrators /add ec2;

          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
        EOH

      end

      it "gets ssl config user data" do
        expect(knife_ec2_create.ssl_config_user_data).to be == @ssl_config_data
      end
    end
  end

  describe "ssl_config_data_already_exist?" do

    before(:each) do
      @user_user_data = "user_user_data.ps1"
      knife_ec2_create.config[:connection_user] = "domain\\ec2"
      knife_ec2_create.config[:connection_password] = "ec2@123"
      knife_ec2_create.config[:aws_user_data] = @user_user_data
    end

    context "ssl config data does not exist in user supplied user_data" do
      before do
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            user_command_1\\\\user_command_2\\\\user_command_3
            user_command_4
          EOH
        end
      end

      it "returns false" do
        expect(knife_ec2_create.ssl_config_data_already_exist?).to eq(false)
      end
    end

    context "ssl config data already exist in user supplied user_data" do
      before do
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
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
            If (-Not $vm_name) {
              $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
            }

            $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
            $name.Encode("CN=$vm_name", 0)
            $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
            $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
            $key.KeySpec = 1
            $key.Length = 2048
            $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
            $key.MachineContext = 1
            $key.Create()
            $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
            $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
            $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
            $ekuoids.add($serverauthoid)
            $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
            $ekuext.InitializeEncode($ekuoids)
            $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
            $cert.InitializeFromPrivateKey(2, $key, "")
            $cert.Subject = $name
            $cert.Issuer = $cert.Subject
            $cert.NotBefore = get-date
            $cert.NotAfter = $cert.NotBefore.AddYears(10)
            $cert.X509Extensions.Add($ekuext)
            $cert.Encode()
            $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
            $enrollment.InitializeFromRequest($cert)
            $certdata = $enrollment.CreateRequest(0)
            $enrollment.InstallResponse(2, $certdata, 0, "")

            $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
            $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
            iex $create_listener_cmd

            netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes

            </powershell>

          EOH
        end
      end

      it "returns false" do
        expect(knife_ec2_create.ssl_config_data_already_exist?).to eq(false)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:aws_user_data)
      FileUtils.rm_rf @user_user_data
    end
  end

  describe "attach ssl config into user data when transport is ssl" do
    require "base64"

    before(:each) do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
      knife_ec2_create.config[:winrm_ssl] = true
      knife_ec2_create.config[:create_ssl_listener] = true
      knife_ec2_create.config[:connection_user] = "domain\\ec2"
      knife_ec2_create.config[:connection_password] = "ec2@123"
    end

    context "when user_data script provided by user contains only <script> section" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <script>

            ipconfig > c:\\ipconfig_data.txt

            </script>
          EOH
        end
        @server_def_user_data = <<~EOH
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
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
          </powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "appends ssl config to user supplied user_data after <script> tag section" do
        server_def = knife_ec2_create.server_attributes
        encoded_data = Base64.encode64(@server_def_user_data)
        expect(server_def[:user_data]).to eq(encoded_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data script provided by user contains <powershell> section" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <powershell>

            Get-DscLocalConfigurationManager > c:\\dsc_data.txt
            </powershell>
          EOH
        end
        @server_def_user_data = <<~EOH
          <powershell>

          Get-DscLocalConfigurationManager > c:\\dsc_data.txt

          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
          </powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "appends ssl config to user supplied user_data at the end of <powershell> tag section" do
        encoded_data = Base64.encode64(@server_def_user_data)
        server_def = knife_ec2_create.server_attributes

        expect(server_def[:user_data]).to eq(encoded_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data script provided by user already contains ssl config code" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <powershell>

            Get-DscLocalConfigurationManager > c:\\dsc_data.txt

            If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
              winrm quickconfig -q
            }
            If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
              winrm delete winrm/config/listener?Address=*+Transport=HTTP
            }
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
            If (-Not $vm_name) {
              $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
            }

            $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
            $name.Encode("CN=$vm_name", 0)
            $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
            $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
            $key.KeySpec = 1
            $key.Length = 2048
            $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
            $key.MachineContext = 1
            $key.Create()
            $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
            $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
            $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
            $ekuoids.add($serverauthoid)
            $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
            $ekuext.InitializeEncode($ekuoids)
            $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
            $cert.InitializeFromPrivateKey(2, $key, "")
            $cert.Subject = $name
            $cert.Issuer = $cert.Subject
            $cert.NotBefore = get-date
            $cert.NotAfter = $cert.NotBefore.AddYears(10)
            $cert.X509Extensions.Add($ekuext)
            $cert.Encode()
            $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
            $enrollment.InitializeFromRequest($cert)
            $certdata = $enrollment.CreateRequest(0)
            $enrollment.InstallResponse(2, $certdata, 0, "")

            $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
            $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
            iex $create_listener_cmd
            netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
            </powershell>
          EOH
        end
        @server_def_user_data = <<~EOH
          <powershell>

          Get-DscLocalConfigurationManager > c:\\dsc_data.txt

          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
          </powershell>
        EOH
        knife_ec2_create.config[:aws_user_data] = @user_user_data
      end

      it "does no modifications and passes user_data as it is to server_def" do
        encoded_data = Base64.encode64(@server_def_user_data)
        server_def = knife_ec2_create.server_attributes

        expect(server_def[:user_data]).to eq(encoded_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data script provided by user has invalid syntax" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
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
        expect { knife_ec2_create.server_attributes }.to raise_error SystemExit
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data script provided by user has <powershell> and <script> tag sections" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <powershell>

            Get-DscLocalConfigurationManager > c:\\dsc_data.txt

            </powershell>
            <script>

            ipconfig > c:\\ipconfig_data.txt

            </script>
          EOH
        end
        @server_def_user_data = <<~EOH
          <powershell>

          Get-DscLocalConfigurationManager > c:\\dsc_data.txt


          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

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
        encoded_data = Base64.encode64(@server_def_user_data)
        server_def = knife_ec2_create.server_attributes

        expect(server_def[:user_data]).to eq(encoded_data)
      end

      after do
        knife_ec2_create.config.delete(:aws_user_data)
        FileUtils.rm_rf @user_user_data
      end
    end

    context "when user_data is not supplied by user on cli" do
      before do
        @server_def_user_data = <<~EOH
          <powershell>

          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
          </powershell>
        EOH
      end

      it "creates user_data only with default ssl configuration" do
        encoded_data = Base64.encode64(@server_def_user_data)
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:user_data]).to eq(encoded_data)
      end
    end

    context "when user has specified --no-create-ssl-listener along with his/her own user_data on cli" do
      before do
        knife_ec2_create.config[:create_ssl_listener] = false
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <powershell>

            Get-DscLocalConfigurationManager > c:\\dsc_data.txt

            </powershell>
            <script>

            ipconfig > c:\\ipconfig_data.txt

            </script>
          EOH
        end
        @server_def_user_data = <<~EOH
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
        encoded_data = Base64.encode64(@server_def_user_data)
        server_def = knife_ec2_create.server_attributes

        expect(server_def[:user_data]).to eq(encoded_data)
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
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:ssh_key_name)
      Chef::Config[:knife].delete(:ssh_key_name)
      knife_ec2_create.config.delete(:winrm_ssl)
      knife_ec2_create.config.delete(:create_ssl_listener)
    end
  end

  describe "do not attach ssl config into user data when transport is plaintext" do
    before(:each) do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      Chef::Config[:knife][:ssh_key_name] = "mykey"
      knife_ec2_create.config[:ssh_key_name] = "ssh_key_name"
      knife_ec2_create.config[:winrm_ssl] = false
    end

    context "when user_data is supplied on cli" do
      before do
        @user_user_data = "user_user_data.ps1"
        File.open(@user_user_data, "w+") do |f|
          f.write <<~EOH
            <script>

            ipconfig > c:\\ipconfig_data.txt
            netstat > c:\\netstat_data.txt

            </script>
          EOH
        end
        knife_ec2_create.config[:aws_user_data] = @user_user_data
        @server_def_user_data = <<~EOH
          <script>

          ipconfig > c:\\ipconfig_data.txt
          netstat > c:\\netstat_data.txt

          </script>
        EOH
      end

      it "user_data is created only with user's user_data" do
        server_def = knife_ec2_create.server_attributes
        encoded_data = Base64.encode64(@server_def_user_data)
        expect(server_def[:user_data]).to eq(encoded_data)
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
        server_def = knife_ec2_create.server_attributes
        expect(server_def[:user_data]).to eq(@server_def_user_data)
      end
    end

    after(:each) do
      knife_ec2_create.config.delete(:ssh_key_name)
      Chef::Config[:knife].delete(:ssh_key_name)
      knife_ec2_create.config.delete(:winrm_ssl)
    end
  end

  describe "disable_api_termination option" do
    before do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
    end
    context "spot instance" do
      context "disable_api_termination is not passed on CLI or in knife config" do
        before do
          knife_ec2_create.config[:spot_price] = 0.001
        end

        it "does not set disable_api_termination option in server_def" do
          server_def = knife_ec2_create.server_attributes
          expect(server_def[:disable_api_termination]).to be_nil
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
        end
      end

      context "disable_api_termination is passed on CLI" do
        before do
          knife_ec2_create.config[:spot_price] = 0.001
          knife_ec2_create.config[:disable_api_termination] = true
        end

        it "raises error" do
          expect(knife_ec2_create.ui).to receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to raise_error(SystemExit)
        end
      end

      context "disable_api_termination is passed in knife config" do
        before do
          knife_ec2_create.config[:spot_price] = 0.001
          Chef::Config[:knife][:disable_api_termination] = true
        end

        it "raises error" do
          expect(knife_ec2_create.ui).to receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to raise_error(SystemExit)
        end
      end
    end

    context "non-spot instance" do
      context "when disable_api_termination option is not passed on the CLI or in the knife config" do

        it "sets disable_api_termination option in server_def with value as false" do
          knife_ec2_create.config[:disable_api_termination] = false # Default
          server_def = knife_ec2_create.server_attributes
          expect(server_def[:disable_api_termination]).to be == false
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
        end
      end

      context "when disable_api_termination option is passed on the CLI" do
        before do
          knife_ec2_create.config[:disable_api_termination] = true
        end

        it "sets disable_api_termination option in server_def with value as true" do
          server_def = knife_ec2_create.server_attributes
          expect(server_def[:disable_api_termination]).to be == true
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
        end
      end

      context "when disable_api_termination option is passed in the knife config" do
        before do
          Chef::Config[:knife][:disable_api_termination] = true
        end

        it "sets disable_api_termination option in server_def with value as true" do
          server_def = knife_ec2_create.server_attributes
          expect(server_def[:disable_api_termination]).to be == true
        end

        it "does not raise error" do
          expect(knife_ec2_create.ui).to_not receive(:error).with(
            "spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances."
          )
          expect { knife_ec2_create.plugin_validate_options! }.to_not raise_error
        end
      end
    end
  end

  describe "disable_source_dest_check option" do
    before do
      expect(knife_ec2_create).to receive(:plugin_validate_options!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      allow(knife_ec2_create).to receive(:server_attributes).and_return(server_attributes)
      expect(ec2_connection).to receive(:run_instances).with(server_attributes).and_return(server_instances)
      knife_ec2_create.config[:yes] = true
      allow(knife_ec2_create).to receive(:instances_wait_until_ready).with("i-00fe186450a2e8e97").and_return(true)
      allow(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"] ).and_return(ec2_servers)
      allow(knife_ec2_create).to receive(:server).and_return(ec2_server_attribs)
    end

    context "when subnet_id and disable_source_dest_check are passed on CLI" do
      let(:network_interfaces) { OpenStruct.new(subnet_id: "subnet-9d4a7b6", source_dest_check: false) }

      it "modify instance attribute source_dest_check as false" do
        allow(knife_ec2_create).to receive_messages(vpc_mode?: true)
        knife_ec2_create.config[:disable_source_dest_check] = true
        expect(ec2_connection).to receive(:modify_instance_attribute)
        server_def = knife_ec2_create.fetch_ec2_instance("i-00fe186450a2e8e97")
        expect(server_def.source_dest_check).to eq(false)
        knife_ec2_create.run
      end
    end
  end

  describe "--security-group-id option" do
    before do
      allow(ec2_server_create).to receive(:validate_aws_config!)
      allow(ec2_server_create).to receive(:validate_nics!)
      allow(ec2_server_create).to receive(:ami).and_return(ami)
    end
    context "when mulitple values provided from cli for e.g. -g sg-aab343ytr -g sg-3764sdss" do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["-g", "sg-aab343ytr", "-g", "sg-3764sdss"]) }
      it "creates array of security group ids" do
        server_def = ec2_server_create.server_attributes
        expect(server_def[:security_group_ids]).to eq(%w{sg-aab343ytr sg-3764sdss})
      end
    end

    context "when single value provided from cli for e.g. --security-group-id 3764sdss" do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--security-group-id", "sg-aab343ytr"]) }
      it "creates array of security group ids" do
        server_def = ec2_server_create.server_attributes
        expect(server_def[:security_group_ids]).to eq(["sg-aab343ytr"])
      end
    end
  end

  describe "--chef-tag option" do
    before do
      allow(ec2_server_create).to receive(:validate_aws_config!)
      allow(ec2_server_create).to receive(:validate_nics!)
      allow(ec2_server_create).to receive(:ami).and_return(ami)
      ec2_server_create.config[:tags] = []
      expect(ec2_server_create.ui).to receive(:warn).with("[DEPRECATED] --chef-tag option is deprecated and will be removed in future release. Use --tags TAGS option instead.")
      ec2_server_create.plugin_validate_options!
    end
    context 'when mulitple values provided from cli for e.g. --chef-tag "foo" --chef-tag "bar"' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--chef-tag", "foo", "--chef-tag", "bar"]) }
      it "creates array of chef tag" do
        expect(ec2_server_create.config[:tags]).to eq(%w{foo bar})
      end
    end

    context "when single value provided from cli for e.g. --chef-tag foo" do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--chef-tag", "foo"]) }
      it "creates array of chef tag" do
        expect(ec2_server_create.config[:tags]).to eq(["foo"])
      end
    end
  end

  describe "--aws-tag option" do
    before do
      allow(ec2_server_create).to receive(:validate_aws_config!)
      allow(ec2_server_create).to receive(:validate_nics!)
      allow(ec2_server_create).to receive(:ami).and_return(ami)
    end

    context 'when mulitple values provided from cli for e.g. --aws-tag "foo=bar" --aws-tag "foo1=bar1"' do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--aws-tag", "foo=bar", "--aws-tag", "foo1=bar1"]) }
      it "creates array of aws tag" do
        server_def = ec2_server_create.config
        expect(server_def[:aws_tag]).to eq(["foo=bar", "foo1=bar1"])
      end
    end

    context "when single value provided from cli for e.g. --aws-tag foo=bar" do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--aws-tag", "foo=bar"]) }
      it "creates array of aws tag" do
        server_def = ec2_server_create.config
        expect(server_def[:aws_tag]).to eq(["foo=bar"])
      end
    end
  end

  describe "evaluate_node_name" do
    before do
      knife_ec2_create.instance_variable_set(:@server, ec2_server_attribs)
    end

    context "when ec2 server attributes are not passed in node name" do
      it "returns the node name unchanged" do
        expect(knife_ec2_create.evaluate_node_name("Test")).to eq("Test")
      end
    end

    context "when %s is passed in the node name" do
      it "returns evaluated node name" do
        expect(knife_ec2_create.evaluate_node_name("Test-%s")).to eq("Test-i-00fe186450a2e8e97")
      end
    end
  end

  describe "Handle password greater than 14 characters" do
    before do
      allow(knife_ec2_create).to receive(:validate_aws_config!)
      allow(knife_ec2_create).to receive(:validate_nics!)
      allow(knife_ec2_create).to receive(:ami).and_return(ami)
      knife_ec2_create.config[:connection_user] = "domain\\ec2"
      knife_ec2_create.config[:connection_password] = "LongPassword@123"
      knife_ec2_create.config[:connection_protocol] = "winrm"
    end

    context "when user enters Y after prompt" do
      before do
        allow(STDIN).to receive_message_chain(:gets, chomp: "Y")
      end
      it "user addition command is executed forcefully" do
        expect(knife_ec2_create.ui).to receive(:warn).with("The password provided is longer than 14 characters. Computers with Windows prior to Windows 2000 will not be able to use this account. Do you want to continue this operation? (Y/N):")
        knife_ec2_create.plugin_validate_options!
        expect(knife_ec2_create.instance_variable_get(:@allow_long_password)).to eq ("/yes")
      end
    end

    context "when user enters n after prompt" do
      before do
        allow(STDIN).to receive_message_chain(:gets, chomp: "N")
      end
      it "operation exits" do
        expect(knife_ec2_create.ui).to receive(:warn).with("The password provided is longer than 14 characters. Computers with Windows prior to Windows 2000 will not be able to use this account. Do you want to continue this operation? (Y/N):")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error("Exiting as operation with password greater than 14 characters not accepted")
      end
    end

    context "when user enters xyz instead of (Y/N) after prompt" do
      before do
        allow(STDIN).to receive_message_chain(:gets, chomp: "xyz")
      end
      it "operation exits" do
        expect(knife_ec2_create.ui).to receive(:warn).with("The password provided is longer than 14 characters. Computers with Windows prior to Windows 2000 will not be able to use this account. Do you want to continue this operation? (Y/N):")
        expect { knife_ec2_create.plugin_validate_options! }.to raise_error("The input provided is incorrect.")
      end
    end
  end

  describe "--primary_eni option" do
    context "when a preexisting eni is specified eg. eni-12345678 use that eni for device index 0" do
      let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--primary-eni", "eni-12345678"]) }
      it "provides a network_interfaces list of hashes with on element for the primary interface" do
        allow(ec2_server_create).to receive(:ami).and_return(ami)
        server_def = ec2_server_create.server_attributes
        expect(server_def[:network_interfaces]).to eq([{ network_interface_id: "eni-12345678", device_index: 0 }])
      end
    end
  end

  describe "device_index for network interfaces" do
    let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--subnet", "subnet-12345678"]) }
    it "when a subnet_id is present set device index 0" do
      allow(ec2_server_create).to receive(:ami).and_return(ami)
      server_def = ec2_server_create.server_attributes
      expect(server_def[:network_interfaces][0][:device_index]).to eq(0)
    end
  end

  describe "disable_source_dest_check option is passed on CLI" do
    let(:ec2_server_create) { Chef::Knife::Ec2ServerCreate.new(["--disable-source-dest-check"]) }
    it "when a disable_source_dest_check is present" do
      expect(ec2_server_create.config[:disable_source_dest_check]).to eq(true)
    end
  end
end
