#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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
    class Ec2SecurityGroupList < Knife

      include Knife::Ec2Base

      banner "knife ec2 security list"
      
      def run
        $stdout.sync = true

        validate!

        security_group_list = [
          ui.color('Name', :bold),
          ui.color('Description', :bold),
          ui.color('Group ID', :bold),
#          ui.color('IP Permissions', :bold),
#          ui.color('IP Permissions Egress', :bold),
          ui.color('VPC ID', :bold)
        ].flatten.compact
        
        output_column_count = security_group_list.length
        
        connection.security_groups.all.each do |security_group|
          security_group_list << security_group.name.to_s
          security_group_list << security_group.description.to_s
          security_group_list << security_group.group_id.to_s
#          security_group_list << security_group.ip_permissions.to_s
#          security_group_list << security_group.ip_permissions_egress.to_s
          security_group_list << security_group.vpc_id.to_s
        end
        puts ui.list(security_group_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end
