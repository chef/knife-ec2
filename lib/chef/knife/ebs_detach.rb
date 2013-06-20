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
    class Ec2EbsDetach < Knife

      include Knife::Ec2Base

      banner "knife ec2 ebs detach VOLUME-ID [VOLUME-ID] (options)"

      option :force,
        :long         => "--force",
        :boolean      => true,
        :description  => "If true forces detach, can cause data loss/corruption"

      def run
        opts = Hash.new
        validate!

        @name_args.each do |volume_id|

          begin
             volume = connection.volumes.get(volume_id)

             msg_pair("Volume ID", volume.id)
             msg_pair("Server ID", volume.server_id)
             msg_pair("Device", volume.device)
             msg_pair("Size (GB)", volume.size)
             msg_pair("Availability Zone", volume.availability_zone)
             msg_pair("Attached", volume.attached_at)

             puts "\n"
             ui.warn("You are using --force") if config[:force]

             confirm("Do you really want to detach this volume")

             opts["force"] = config[:force] if config[:force]
             connection.detach_volume(volume.id, opts)

             ui.warn("Detached volume #{volume.id}")

          rescue NoMethodError
             ui.error("Could not locate volume '#{volume_id}'.")
          end
        end
      end
    end
  end
end
