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
    class Ec2VpcList < Knife

      include Knife::Ec2Base

      banner "knife ec2 vpc list (options)"

      def run
        validate!
        custom_warnings!

        vpcs_list = [
          ui.color("ID", :bold),
          ui.color("State", :bold),
          ui.color("CIDR Block", :bold),
          ui.color("Instance Tenancy", :bold),
          ui.color("DHCP Options ID", :bold),
          ui.color("Default VPC?", :bold)
        ].flatten.compact

        output_column_count = vpcs_list.length

        if config[:format] == "summary"
          vpc_hash.each_pair do |_k, v|
            vpcs_list << v["vpc_id"]
            vpcs_list << v["state"]
            vpcs_list << v["cidr_block"]
            vpcs_list << v["instance_tenancy"]
            vpcs_list << v["dhcp_options_id"]
            vpcs_list << (v["is_default"] ? "Yes" : "No")
          end
          puts ui.list(vpcs_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(vpc_hash))
        end
      end

      private

      def vpc_hash
        all_data = {}
        connection.describe_vpcs.first.vpcs.each do |v|
          v_data = {}
          %w{vpc_id cidr_block dhcp_options_id instance_tenancy is_default state}.each do |id|
            v_data[id] = v.send(id)
          end
          all_data[v_data["vpc_id"]] = v_data
        end
        all_data
      end
    end
  end
end
