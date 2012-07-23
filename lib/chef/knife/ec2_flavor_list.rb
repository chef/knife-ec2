#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
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
    class Ec2FlavorList < Knife

      include Knife::Ec2Base

      banner "knife ec2 flavor list (options)"

      def run

        validate!

        flavor_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('Architecture', :bold),
          ui.color('RAM', :bold),
          ui.color('Disk', :bold),
          ui.color('Cores', :bold)
        ]
        connection.flavors.sort_by(&:id).each do |flavor|
          flavor_list << flavor.id.to_s
          flavor_list << flavor.name
          flavor_list << "#{flavor.bits.to_s}-bit"
          flavor_list << "#{flavor.ram.to_s}"
          flavor_list << "#{flavor.disk.to_s} GB"
          flavor_list << flavor.cores.to_s
        end
        puts ui.list(flavor_list, :columns_across, 6)
      end
    end
  end
end
