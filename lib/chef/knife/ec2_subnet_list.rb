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
    class Ec2SubnetList < Knife

      include Knife::Ec2Base

      banner "knife ec2 subnet list (options)"

      def run
        validate!
        custom_warnings!

        subnet_list = [
          ui.color("ID", :bold),
          ui.color("State", :bold),
          ui.color("CIDR Block", :bold),
          ui.color("AZ", :bold),
          ui.color("Available IPs", :bold),
          ui.color("AZ Default?", :bold),
          ui.color("Maps Public IP?", :bold),
          ui.color("VPC ID", :bold)
        ].flatten.compact

        output_column_count = subnet_list.length

        if config[:format] == "summary"
          subnet_hash.each_pair do |_k, v|
            subnet_list << v["subnet_id"]
            subnet_list << v["state"]
            subnet_list << v["cidr_block"]
            subnet_list << v["availability_zone"]
            subnet_list << v["available_ip_address_count"].to_s
            subnet_list << (v["default_for_az"] ? "Yes" : "No")
            subnet_list << (v["map_public_ip_on_launch"] ? "Yes" : "No")
            subnet_list << v["vpc_id"]
          end
          puts ui.list(subnet_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(subnet_hash))
        end
      end

      def subnet_hash
        all_data = {}
        connection.describe_subnets.first.subnets.each do |s|
          s_data = {}
          %w{subnet_id availability_zone available_ip_address_count cidr_block default_for_az map_public_ip_on_launch state vpc_id}.each do |id|
            s_data[id] = s.send(id)
          end
          all_data[s_data["subnet_id"]] = s_data
        end
        all_data
      end
    end
  end
end
