#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2018 Chef Software, Inc.
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

require "chef/knife/ec2_base"

class Chef
  class Knife
    class Ec2SecuritygroupList < Knife

      include Knife::Ec2Base

      banner "knife ec2 securitygroup list (options)"

      def run
        validate!
        custom_warnings!

        sg_list = [
          ui.color("ID", :bold),
          ui.color("Name", :bold),
          ui.color("VPC ID", :bold)
        ].flatten.compact

        output_column_count = sg_list.length

        if config[:format] == "summary"
          sg_hash.each_pair do |_k, v|
            sg_list << v["group_id"]
            sg_list << v["group_name"]
            sg_list << v["vpc_id"]
          end
          puts ui.list(sg_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(sg_hash))
        end
      end

      private

      def sg_hash
        all_data = {}
        connection.describe_security_groups.first.security_groups.each do |s|
          s_data = {}
          %w{group_name group_id vpc_id}.each do |id|
            s_data[id] = s.send(id)
          end
          all_data[s_data["group_id"]] = s_data
        end
        all_data
      end
    end
  end
end
