#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2009-2011 Opscode, Inc.
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
    class Ec2ServerDelete < Knife

      include Knife::Ec2Base

      banner "knife ec2 server delete SERVER [SERVER] (options)"

      def run

        validate!

        @name_args.each do |instance_id|

          begin
            server = connection.servers.get(instance_id)

            msg_pair("Instance ID", server.id)
            msg_pair("Flavor", server.flavor_id)
            msg_pair("Image", server.image_id)
            msg_pair("Region", connection.instance_variable_get(:@region))
            msg_pair("Availability Zone", server.availability_zone)
            msg_pair("Security Groups", server.groups.join(", "))
            msg_pair("SSH Key", server.key_name)
            msg_pair("Root Device Type", server.root_device_type)
            msg_pair("Public DNS Name", server.dns_name)
            msg_pair("Public IP Address", server.public_ip_address)
            msg_pair("Private DNS Name", server.private_dns_name)
            msg_pair("Private IP Address", server.private_ip_address)

            puts "\n"
            confirm("Do you really want to delete this server")

            server.destroy

            ui.warn("Deleted server #{server.id}")

          rescue NoMethodError
            ui.error("Could not locate server '#{instance_id}'.  Please verify it was provisioned in the '#{locate_config_value(:region)}' region.")
          end
        end
      end

    end
  end
end

