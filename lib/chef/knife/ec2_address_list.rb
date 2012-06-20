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
    class Ec2AddressList < Knife

      include Knife::Ec2Base

      banner "knife ec2 address list (options)"

      def run
        $stdout.sync = true

        validate!

        ips_list = [
          ui.color('Public IP', :bold),
          ui.color('Instance ID', :bold),
          ui.color('Domain', :bold),
          ui.color('Allocation ID', :bold),
          ui.color('Association ID', :bold)
        ]

        connection.describe_addresses.body['addressesSet'].each do |ip|
          ips_list << ip['publicIp'].to_s
          ips_list << ip['instanceId'].to_s
          ips_list << ip['domain'].to_s
          ips_list << ip['allocationId'].to_s
          ips_list << ip['associationId'].to_s
        end

        puts ui.list(ips_list, :uneven_columns_across, 5)

      end
    end
  end
end


