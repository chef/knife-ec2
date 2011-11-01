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

describe Chef::Knife::Ec2ServerList do
  let(:ec2_server_list) do
    described_class.new
  end
  
  specify do
    should be_a_kind_of(Chef::Knife)
  end
  
  describe "#run" do
    subject do
      ec2_server_list.run
    end
    
    context "when valid" do
      before do
        ec2_server_list.stub!(:validate!).and_return true
      end
      
      context "when servers" do
        before do
          ec2_server_list.stub_chain('connection.servers.all').and_return servers
        end
        
        let(:servers) do
          3.times.map do |i|
            server_attribs = {
              :id => "i-3938231#{i}",
              :flavor_id => 'm1.small',
              :image_id => 'ami-47241231',
              :availability_zone => 'us-west-1',
              :key_name => 'my_ssh_key',
              :groups => ['group1', 'group2'],
              :public_ip_address => "75.101.253.1#{i}",
              :private_ip_address => "10.251.75.2#{i}",
              :state => 'running'
            }
            mock('server', server_attribs)
          end
        end
        
        it "returns a list of EC2 servers" do
          output = capture(:stdout) { subject.should == nil }
          output.should == <<-EOF
Instance ID      Public IP        Private IP       Flavor           Image            SSH Key          Security Groups  State          
i-39382310       75.101.253.10    10.251.75.20     m1.small         ami-47241231     my_ssh_key       group1, group2   running        
i-39382311       75.101.253.11    10.251.75.21     m1.small         ami-47241231     my_ssh_key       group1, group2   running        
i-39382312       75.101.253.12    10.251.75.22     m1.small         ami-47241231     my_ssh_key       group1, group2   running        
          EOF
        end
      end

      context "when no servers" do
        before do
          ec2_server_list.stub_chain('connection.servers.all').and_return servers
        end
        
        let(:servers) do
          []
        end

        it "returns an empty list" do
          output = capture(:stdout) { subject.should == nil }
          output.should == <<-EOF
Instance ID      Public IP        Private IP       Flavor           Image            SSH Key          Security Groups  State          
          EOF
        end
      end
    end
  end
end