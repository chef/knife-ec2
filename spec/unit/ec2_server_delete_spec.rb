#
# Author:: Grégory Karékinian (<greg@greenalto.com>)
# Copyright:: Copyright (c) 2010 Grégory Karékinian
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

require 'chef/knife/bootstrap'

describe Chef::Knife::Ec2ServerDelete do
  let(:instance_ids) do
    3.times.map { |i| "i-3938231#{i}" }
  end
  
  let(:ec2_server_delete) do
    described_class.new(instance_ids)
  end
  
  describe "#run" do
    subject do
      ec2_server_delete.run
    end
    
    # Fog
    let(:connection) do
      mock('connection', :region => 'us-west')
    end
    
    let(:servers) do
      3.times.map do |i|
        server_attribs = {
          :id => instance_ids[i],
          :flavor_id => 'm1.small',
          :image_id => 'ami-47241231',
          :availability_zone => 'us-west-1',
          :key_name => 'my_ssh_key',
          :root_device_type => 'root_device_type',
          :groups => ['group1', 'group2'],
          :dns_name => "ec2-75-101-253-1#{i}.us-west-1.compute.amazonaws.com",
          :public_ip_address => "75.101.253.1#{i}",
          :private_dns_name => "10-251-75-2#{i}.compute.internal",
          :private_ip_address => "10.251.75.2#{i}"
        }
        mock("server", server_attribs)
      end
    end

    before do
      # Valid request
      {
        :aws_access_key_id => 'aws_access_key_id',
        :aws_secret_access_key => 'aws_secret_access_key'
      }.each do |key, value|
        Chef::Config[:knife][key] = value
      end 
      
      ec2_server_delete.stub!(:connection).and_return connection
      connection.stub!(:servers).and_return connection_servers
    end
    
    context "when servers exist in the region" do
      let(:connection_servers) { mock('servers') }
      
      it "deletes the servers" do
        instance_ids.each_with_index do |instance_id, index|
          server = servers[index]
          connection_servers.should_receive(:get).with(instance_id).and_return server
          ec2_server_delete.should_receive(:confirm).and_return true
          server.should_receive(:destroy)
          
          # FIXME: Try to capture stderr instead
          ec2_server_delete.ui.should_receive(:warn).with("Deleted server #{instance_id}")
        end
        
        capture(:stdout) { subject }
      end
    end
    
    context "when server does not exist in the region" do
      let(:connection_servers) do
        []
      end
      
      it "displays an error message" do
        instance_ids.each_with_index do |instance_id, index|
          # FIXME: Try to capture stderr instead
          ec2_server_delete.ui.should_receive(:error).with("Could not locate server '#{instance_id}'.  Please verify it was provisioned in the 'us-east-1' region.")
        end
        
        subject
      end
    end
  end
end