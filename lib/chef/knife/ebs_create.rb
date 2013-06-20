#
# Author:: Denis Corol (<dcorol@gmail.com>)
# Copyright:: Copyright (c) 2013
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

require 'chef/knife/ec2_base'

class Chef
  class Knife
    class Ec2EbsCreate < Knife

      include Knife::Ec2Base

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife ec2 ebs create (options)"

      attr_accessor :initial_sleep_delay

      option :availability_zone,
        :short => "-Z ZONE",
        :long => "--availability-zone ZONE",
        :description => "The Availability Zone",
        :default => "us-east-1a",
        :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :ebs_size,
        :short => "-S SIZE",
        :long => "--size SIZE",
        :description => "The size of the EBS volume in GB"

      option :device,
        :short => "-D DEVICE",
        :long => "--device DEVICE",
        :description => "Attach as device, ex: /dev/sdg. Only works with --server",
        :default => ""

      option :instance_id,
        :short => "-S INSTANCE-ID",
        :long => "--server INSTANCE-ID",
        :description => "Id of instance to associate volume with",
        :default => ""
        
      def run
        $stdout.sync = true

        validate!
        
        volume = connection.volumes.new(create_volume_def)
        volume.device = config[:device] if !config[:device].empty?
        volume.server = connection.servers.get(config[:instance_id]) if !config[:instance_id].empty?
        
        msg_pair("Availability Zone", volume.availability_zone)
        msg_pair("Size (GB)", volume.size)

        volume.save

        msg_pair("Volume ID", volume.id)

        print "\n#{ui.color("Waiting for volume", :magenta)}"
        # wait for it to be ready to do stuff
        volume.wait_for { 
          sleep(10)
          print "."
          connection.volumes.get(volume.id).ready? or 
            connection.volumes.get(volume.id).state == "in-use" or
            connection.volumes.get(volume.id).state == "attached"
        }
        puts "\n"

        volume.reload

        volume
      end

      def create_volume_def
        ebs_size = begin
                     if config[:ebs_size]
                       Integer(config[:ebs_size]).to_s
                     end
                   rescue ArgumentError
                     puts "--ebs-size must be an integer"
                     msg opt_parser
                     exit 1
                   end

        volume_def = {
          :availability_zone => locate_config_value(:availability_zone),
          :size => ebs_size
        }
        volume_def
      end
    end
  end
end
