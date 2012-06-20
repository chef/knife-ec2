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
    class Ec2AddressRelease < Knife

      include Knife::Ec2Base

      banner "knife ec2 address release IP (options)"

      def run
        $stdout.sync = true

        validate!

        unless @name_args.length == 1
          show_usage
          ui.fatal("You must specify the ip")
          exit 1
        end

        ip = @name_args.first

        address_set = connection.describe_addresses.body['addressesSet']
        unless address_set.any? {|rec| rec['publicIp'] == ip}
          ui.fatal("The specified IP, '#{ip}', could not be found.")
          exit 1
        end

        connection.release_address(ip)
      end
    end
  end
end

