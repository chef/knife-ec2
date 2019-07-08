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
require "aws-sdk-ec2"

describe Chef::Knife::Ec2ServerDelete do
  describe "run" do
    let(:knife_ec2_delete) { Chef::Knife::Ec2ServerDelete.new }
    let(:ebs) { OpenStruct.new(volume_size: 30) }
    let(:placement) { OpenStruct.new(tenancy: "default") }
    let(:security_groups) { [OpenStruct.new(group_id: "s-gr446f", group_name: "default-vpc")] }
    let(:tags) { [OpenStruct.new(key: "Name", value: "ec2-test")] }
    let(:block_device_mappings) { OpenStruct.new(ebs: ebs) }
    let(:instance1) do
      OpenStruct.new(
        architecture: "x86_64",
        image_id: "ami-005bdb005fb00e791",
        instance_id: "i-00fe186450a2e8e97",
        instance_type: "t2.micro",
        platform: "windows",
        name: "image-test",
        description: "test windows winrm image",
        block_device_mappings: [block_device_mappings],
        placement: placement,
        security_groups: security_groups,
        tags: tags
      )
    end

    let(:server_instances)  { OpenStruct.new(instances: [instance1]) }
    let(:ec2_servers)       { OpenStruct.new(reservations: [server_instances]) }
    let(:ec2_connection)    { Aws::EC2::Client.new(stub_responses: true) }

    before(:each) do
      allow(knife_ec2_delete).to receive(:ec2_connection).and_return ec2_connection
      allow(knife_ec2_delete.ui).to receive(:confirm)
      allow(knife_ec2_delete).to receive(:msg_pair)
      allow(knife_ec2_delete.ui).to receive(:warn)
    end

    it "should invoke validate_aws_config!" do
      allow(ec2_connection).to receive(:describe_instances).and_return(ec2_servers)
      expect(knife_ec2_delete).to receive(:validate_aws_config!)
      allow(knife_ec2_delete).to receive(:validate_instances!)
      knife_ec2_delete.run
    end

    it "should use invoke aws api to delete instance if instance id is passed" do
      expect(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"]).and_return(ec2_servers)
      knife_ec2_delete.name_args = ["i-00fe186450a2e8e97"]
      expect(knife_ec2_delete).to receive(:validate_aws_config!)
      expect(knife_ec2_delete).to receive(:validate_instances!)
      expect(ec2_connection).to receive(:terminate_instances)
      knife_ec2_delete.run
    end

    it "should use node_name to figure out instance id if not specified explicitly" do
      expect(ec2_connection).to receive(:describe_instances).and_return(ec2_servers)
      expect(knife_ec2_delete).to receive(:validate_aws_config!)
      expect(knife_ec2_delete.ui).to receive(:info)
      knife_ec2_delete.config[:purge] = false
      knife_ec2_delete.config[:chef_node_name] = "baz"
      double_node = double(Chef::Node)
      expect(double_node).to receive(:attribute?).with("ec2").and_return(true)
      expect(double_node).to receive(:[]).with("ec2").and_return("instance_id" => "i-00fe186450a2e8e97")
      double_search = double(Chef::Search::Query)
      expect(double_search).to receive(:search).with(:node, "name:baz").and_return([[double_node], nil, nil])
      expect(Chef::Search::Query).to receive(:new).and_return(double_search)
      knife_ec2_delete.name_args = []
      knife_ec2_delete.run
    end

    describe "when --purge is passed" do
      it "should use the node name if its set" do
        expect(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"]).and_return(ec2_servers)
        knife_ec2_delete.name_args = ["i-00fe186450a2e8e97"]
        expect(knife_ec2_delete).to receive(:validate_aws_config!)
        expect(ec2_connection).to receive(:terminate_instances)
        knife_ec2_delete.config[:purge] = true
        knife_ec2_delete.config[:chef_node_name] = "baz"
        expect(Chef::Node).to receive(:load).with("baz").and_return(double(destroy: true))
        expect(Chef::ApiClient).to receive(:load).with("baz").and_return(double(destroy: true))
        knife_ec2_delete.run
      end

      it "should search for the node name using the instance id when node name is not specified" do
        expect(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"]).and_return(ec2_servers)
        knife_ec2_delete.name_args = ["i-00fe186450a2e8e97"]
        expect(knife_ec2_delete).to receive(:validate_aws_config!)
        expect(ec2_connection).to receive(:terminate_instances)
        knife_ec2_delete.config[:purge] = true
        knife_ec2_delete.config[:chef_node_name] = nil
        double_search = double(Chef::Search::Query)
        double_node = double(Chef::Node)
        expect(double_node).to receive(:name).and_return("baz")
        expect(Chef::Node).to receive(:load).with("baz").and_return(double(destroy: true))
        expect(Chef::ApiClient).to receive(:load).with("baz").and_return(double(destroy: true))
        expect(double_search).to receive(:search).with(:node, "ec2_instance_id:i-00fe186450a2e8e97").and_return([[double_node], nil, nil])
        expect(Chef::Search::Query).to receive(:new).and_return(double_search)
        knife_ec2_delete.run
      end

      it "should use  the instance id if search does not return anything" do
        expect(ec2_connection).to receive(:describe_instances).with(instance_ids: ["i-00fe186450a2e8e97"]).and_return(ec2_servers)
        knife_ec2_delete.name_args = ["i-00fe186450a2e8e97"]
        expect(knife_ec2_delete).to receive(:validate_aws_config!)
        expect(ec2_connection).to receive(:terminate_instances)
        knife_ec2_delete.config[:purge] = true
        knife_ec2_delete.config[:chef_node_name] = nil
        expect(Chef::Node).to receive(:load).with("i-00fe186450a2e8e97").and_return(double(destroy: true))
        expect(Chef::ApiClient).to receive(:load).with("i-00fe186450a2e8e97").and_return(double(destroy: true))
        double_search = double(Chef::Search::Query)
        expect(double_search).to receive(:search).with(:node, "ec2_instance_id:i-00fe186450a2e8e97").and_return([[], nil, nil])
        expect(Chef::Search::Query).to receive(:new).and_return(double_search)
        knife_ec2_delete.run
      end
    end
  end
end
