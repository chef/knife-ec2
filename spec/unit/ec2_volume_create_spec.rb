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
describe Chef::Knife::Ec2VolumeCreate do
  before(:each) do
    @knife_volume_create = Chef::Knife::Ec2VolumeCreate.new
  end

  describe "config options" do
    it "sets the availability zone from CLI arguments over knife config" do
      @knife_volume_create.config[:availability_zone] = "dis-one"
      Chef::Config[:knife][:availability_zone] = "dat-one"
      avaiability_zone = @knife_volume_create.availability_zone

      avaiability_zone.should == "dis-one"
    end

    it "sets the volume size from CLI arguments over knife config" do
      @knife_volume_create.config[:volume_size] = 5
      Chef::Config[:knife][:volume_size] = 10
      volume_size = @knife_volume_create.volume_size

      volume_size.should == 5
    end
  end

  describe ".run" do
    before do
      {
        :aws_access_key_id => 'aws_access_key_id',
        :aws_secret_access_key => 'aws_secret_access_key'
      }.each do |key, value|
        Chef::Config[:knife][key] = value
      end

      @ec2_connection = double(Fog::Compute::AWS)
      @knife_volume_create.should_receive(:connection).twice.and_return(@ec2_connection)
    end


    it "passes along the availability and volume size to the create_volume" do
      Chef::Config[:knife][:availability_zone] = "us-east-1a"
      Chef::Config[:knife][:volume_size] = 5
      @knife_volume_create.connection.should_receive(:create_volume).with("us-east-1a", 5).and_return(create_volume_response)

      @knife_volume_create.run

      @knife_volume_create.should_not == nil
    end

    def create_volume_response
      double(data: {body: {"availabilityZone" => "us-east-1a", "size" => "5"}})
    end
  end
end
