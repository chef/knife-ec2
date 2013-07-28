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


describe Chef::Knife::Ec2ServerDelete do
  before do
  end

  describe "run" do
    before(:each) do
      {
        :image => 'image',
        :aws_ssh_key_id => 'aws_ssh_key_id',
        :aws_access_key_id => 'aws_access_key_id',
        :aws_secret_access_key => 'aws_secret_access_key'
      }.each do |key, value|
        Chef::Config[:knife][key] = value
      end

      @ec2_server_attribs = { :id => 'i-39382318',
                             :flavor_id => 'm1.small',
                             :image_id => 'ami-47241231',
                             :availability_zone => 'us-west-1',
                             :key_name => 'my_ssh_key',
                             :groups => ['group1', 'group2'],
                             :security_group_ids => ['sg-00aa11bb'],
                             :dns_name => 'ec2-75.101.253.10.compute-1.amazonaws.com',
                             :iam_instance_profile => {}, 
                             :public_ip_address => '75.101.253.10',
                             :private_dns_name => 'ip-10-251-75-20.ec2.internal',
                             :private_ip_address => '10.251.75.20',
                             :root_device_type => 'not_ebs' }
        @knife_ec2_delete = Chef::Knife::Ec2ServerDelete.new
        @ec2_servers = double()
        @knife_ec2_delete.ui.stub(:confirm)
        @knife_ec2_delete.stub(:msg_pair)
        @ec2_server = double(@ec2_server_attribs)
        @ec2_connection = double(Fog::Compute::AWS)
        @ec2_connection.stub(:servers).and_return(@ec2_servers)
        @knife_ec2_delete.ui.stub(:warn)
      end

    it "should invoke validate!" do
      knife_ec2_delete = Chef::Knife::Ec2ServerDelete.new
      knife_ec2_delete.should_receive(:validate!)
      knife_ec2_delete.run
    end

    it "should use invoke fog api to delete instance if instance id is passed" do
      @ec2_servers.should_receive(:get).with('foo').and_return(@ec2_server)
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
      @knife_ec2_delete.name_args = ['foo']
      @knife_ec2_delete.should_receive(:validate!)
      @ec2_server.should_receive(:destroy)
      @knife_ec2_delete.run
    end

    it "should use node_name to figure out instance id if not specified explicitly" do
        @ec2_servers.should_receive(:get).with('foo').and_return(@ec2_server)
        Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
        @knife_ec2_delete.should_receive(:validate!)
        @ec2_server.should_receive(:destroy)
        @knife_ec2_delete.config[:purge] = false
        @knife_ec2_delete.config[:chef_node_name] = 'baz'
        double_node = double(Chef::Node)
        double_node.should_receive(:attribute?).with('ec2').and_return(true)
        double_node.should_receive(:[]).with('ec2').and_return('instance_id'=>'foo')
        double_search = double(Chef::Search::Query)
        double_search.should_receive(:search).with(:node,"name:baz").and_return([[double_node],nil,nil])
        Chef::Search::Query.should_receive(:new).and_return(double_search)
        @knife_ec2_delete.name_args = []
        @knife_ec2_delete.run
    end

    describe "when --purge is passed" do
      it "should use the node name if its set" do
        @ec2_servers.should_receive(:get).with('foo').and_return(@ec2_server)
        Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
        @knife_ec2_delete.name_args = ['foo']
        @knife_ec2_delete.should_receive(:validate!)
        @ec2_server.should_receive(:destroy)
        @knife_ec2_delete.config[:purge] = true
        @knife_ec2_delete.config[:chef_node_name] = 'baz'
        Chef::Node.should_receive(:load).with('baz').and_return(double(:destroy=>true))
        Chef::ApiClient.should_receive(:load).with('baz').and_return(double(:destroy=>true))
        @knife_ec2_delete.run
      end

      it "should search for the node name using the instance id when node name is not specified" do
        @ec2_servers.should_receive(:get).with('i-foo').and_return(@ec2_server)
        Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
        @knife_ec2_delete.name_args = ['i-foo']
        @knife_ec2_delete.should_receive(:validate!)
        @ec2_server.should_receive(:destroy)
        @knife_ec2_delete.config[:purge] = true
        @knife_ec2_delete.config[:chef_node_name] = nil
        double_search = double(Chef::Search::Query)
        double_node = double(Chef::Node)
        double_node.should_receive(:name).and_return("baz")
        Chef::Node.should_receive(:load).with('baz').and_return(double(:destroy=>true))
        Chef::ApiClient.should_receive(:load).with('baz').and_return(double(:destroy=>true))
        double_search.should_receive(:search).with(:node,"ec2_instance_id:i-foo").and_return([[double_node],nil,nil])
        Chef::Search::Query.should_receive(:new).and_return(double_search)
        @knife_ec2_delete.run
      end

      it "should use  the instance id if search does not return anything" do
        @ec2_servers.should_receive(:get).with('i-foo').and_return(@ec2_server)
        Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
        @knife_ec2_delete.name_args = ['i-foo']
        @knife_ec2_delete.should_receive(:validate!)
        @ec2_server.should_receive(:destroy)
        @knife_ec2_delete.config[:purge] = true
        @knife_ec2_delete.config[:chef_node_name] = nil
        Chef::Node.should_receive(:load).with('i-foo').and_return(double(:destroy=>true))
        Chef::ApiClient.should_receive(:load).with('i-foo').and_return(double(:destroy=>true))
        double_search = double(Chef::Search::Query)
        double_search.should_receive(:search).with(:node,"ec2_instance_id:i-foo").and_return([[],nil,nil])
        Chef::Search::Query.should_receive(:new).and_return(double_search)
        @knife_ec2_delete.run
      end
    end
  end
end
