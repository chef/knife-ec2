
#
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
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
require 'chef/knife/ec2_server_delete'
require 'chef/knife/cloud/ec2_service'

describe Chef::Knife::Cloud::Ec2ServerDelete do

  before do
    @ec2_connection = double(Fog::Compute::AWS)
    @chef_node = double(Chef::Node)
    @chef_client = double(Chef::ApiClient)
    @knife_ec2_delete = Chef::Knife::Cloud::Ec2ServerDelete.new
    {
      :aws_access_key_id => 'aws_access_key_id',
      :aws_secret_access_key => 'aws_secret_access_key',
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    @ec2_service = Chef::Knife::Cloud::Ec2Service.new
    @ec2_service.stub(:msg_pair)
    @knife_ec2_delete.stub(:create_service_instance).and_return(@ec2_service)
    @knife_ec2_delete.ui.stub(:warn)
    @knife_ec2_delete.ui.stub(:confirm)
    @ec2_servers = double()
    @running_ec2_server = double()
    @ec2_server_attribs = { :tags => {'Name' =>  'Mock Server'},
                            :id => 'id-123456',
                            :key_name => 'key_name',

                          }

    @ec2_server_attribs.each_pair do |attrib, value|
      @running_ec2_server.stub(attrib).and_return(value)
    end
    @knife_ec2_delete.name_args = ['test001']
  end

  describe "run" do
    it "deletes an Ec2 instance." do
      @ec2_servers.should_receive(:get).and_return(@running_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
      @running_ec2_server.should_receive(:destroy)
      @knife_ec2_delete.run
    end

    it "deletes the instance along with the node and client on the chef-server when --purge is given as an option." do
      @knife_ec2_delete.config[:purge] = true
      @knife_ec2_delete.should_receive(:fetch_node_name).and_return("testnode")
      Chef::Node.should_receive(:load).and_return(@chef_node)
      @chef_node.should_receive(:destroy)
      Chef::ApiClient.should_receive(:load).and_return(@chef_client)
      @chef_client.should_receive(:destroy)
      @ec2_servers.should_receive(:get).and_return(@running_ec2_server)
      @ec2_connection.should_receive(:servers).and_return(@ec2_servers)
      Fog::Compute::AWS.should_receive(:new).and_return(@ec2_connection)
      @running_ec2_server.should_receive(:destroy)
      @knife_ec2_delete.run
    end
  end
end
