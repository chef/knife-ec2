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
    class Ec2DnsList < Knife

      include Knife::Ec2Base

      banner "knife ec2 dns list (options)"

      def run
        $stdout.sync = true

        validate!

        zones_list = [
          ui.color('Zone Id', :bold),
          ui.color('Domain', :bold),
          ui.color('Records', :bold),
          ui.color('Caller Reference', :bold),
          ui.color('Description', :bold)
        ]

        dns.zones.all.each do |zone|
          zones_list << zone.id.to_s
          zones_list << zone.domain.to_s
          zones_list << zone.records.all.size.to_s
          zones_list << zone.caller_reference.to_s || ""
          zones_list << zone.description.to_s
        end
        puts ui.list(zones_list, :columns_across, 5)
      end
    end
  end
end


