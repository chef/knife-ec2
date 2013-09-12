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
    class Ec2EbsList < Knife

      include Knife::Ec2Base

      banner "knife ec2 ebs list (options)"

      def run
        $stdout.sync = true

        validate!

        volume_list = [
          ui.color('ID', :bold),
          ui.color('Zone', :bold),
          ui.color('Device', :bold),
          ui.color('Server', :bold),
          ui.color('Size', :bold),
          ui.color('Snapshot ID', :bold),
          ui.color('State', :bold)
        ]

        connection.volumes.all.each do |volume|
          volume_list << volume.id.to_s
          volume_list << volume.availability_zone.to_s
          volume_list << volume.device.to_s
          volume_list << volume.server_id.to_s
          volume_list << volume.size.to_s
          volume_list << volume.snapshot_id.to_s
          volume_list << begin
            state = volume.state.to_s.downcase
            case state
            when 'in-use'
              ui.color(state, :red)
            when 'creating'
              ui.color(state, :yellow)
            else
              ui.color(state, :green)
            end
          end
        end
        puts ui.list(volume_list, :uneven_columns_across, 7)
      end
    end
  end
end
