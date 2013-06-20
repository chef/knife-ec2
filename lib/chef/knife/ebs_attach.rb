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
    class Ec2EbsAttach < Knife

      include Knife::Ec2Base

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife ec2 ebs attach (options)"

      option :instance_id,
        :short => "-S INSTANCE-ID",
        :long => "--server INSTANCE-ID",
        :description => "Id of instance to associate volume with"

      option :volume_id,
        :short => "-I VOLUME-ID",
        :long => "--volume VOLUME-ID",
        :description => "Id of amazon EBS volume to associate with instance"

      option :device_name,
        :short => "-d DEVICE",
        :long => "--device DEVICE",
        :description => "Specifies how the device is exposed to the instance (e.g. '/dev/sdh')"

#
# Todo: check if the volume is not in use
#

      def run
        $stdout.sync = true

        validate!

        vol_id = config[:volume_id]
        srv_id = config[:instance_id]
        dev_name = config[:device_name]

        volume = connection.volumes.get(attach_volume_def[1])
        server = connection.servers.get(attach_volume_def[0])

        ui.info("Attaching volume")
        msg_pair("Volume ID", volume.id)
        msg_pair("Size (GB)", volume.size)
        msg_pair("Availability Zone", volume.availability_zone)
        msg_pair("Attached", volume.attached_at)
        msg_pair("Device", volume.device)

        puts "\n"

        ui.info("to Instance")
        msg_pair("Name", server.tags["Name"].to_s)
        msg_pair("Instance ID", server.id)
        msg_pair("Availability Zone", server.availability_zone)
        msg_pair("Public DNS Name", server.dns_name)

        puts "\n"

        ui.info("as device")
        msg_pair("Device Name", attach_volume_def[2])

        connection.attach_volume(*attach_volume_def)
        volume.wait_for { sleep(5); print "."; state == "in-use" }
        puts "\n\n"
        ui.info("Attached")

      end

      def attach_volume_def
        volume_def = [
          config[:instance_id],
          config[:volume_id],
          config[:device_name]
        ]
        volume_def
      end
    end
  end
end
