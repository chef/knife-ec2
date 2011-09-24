#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Bulat Shakirzyanov (<mallluhuct@gmail.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
    class Ec2DnsDelete < Knife

      include Knife::Ec2Base

      banner "knife ec2 dns delete DOMAINS"

      def run
        $stdout.sync = true

        validate!

        @name_args.each do |zone_id|
          zone = dns.zones.get(zone_id)

          msg_pair("Zone Id", zone.id)
          msg_pair("Domain", zone.domain)
          msg_pair("Nameservers", zone.nameservers.to_s)
          msg_pair("Records", zone.records.all.size.to_s)
          msg_pair("Caller Reference", zone.caller_reference)
          msg_pair("Description", zone.description.to_s)
          msg_pair("Change Info", zone.change_info.to_s)

          puts "\n"
          confirm("Do you really want to delete this zone")

          zone.destroy

          ui.warn("Deleted zone #{zone.domain}")
        end
      end
    end
  end
end


