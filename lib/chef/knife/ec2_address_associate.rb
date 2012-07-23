#
# Author:: Alfred Rossi (<alfred@actionverb.com>)
# Copyright:: Copyright (c) 2012 Action Verb, LLC.
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
    class Ec2AddressAssociate < Knife

      include Knife::Ec2Base

      banner "knife ec2 address associate INSTANCE_ID PUBLIC_IP (options)"

      def run
        $stdout.sync = true

        validate!

        unless @name_args.length == 2
          show_usage
          ui.fatal("You must and may only specify both an instance id and public ip")
          exit 1
        end

        instance_id, ip = @name_args

        address_set = connection.describe_addresses.body['addressesSet']

        unless address_set.any? {|rec| rec['publicIp'] == ip}
          ui.fatal("The specified IP, '#{ip}', could not be found.")
          exit 1
        end

        unless connection.servers.any? {|server| server.id == instance_id}
          ui.fatal("The specified instance id, '#{instance_id}', could not be found.")
          exit 1
        end

        connection.associate_address(instance_id, ip)
      end
    end
  end
end

