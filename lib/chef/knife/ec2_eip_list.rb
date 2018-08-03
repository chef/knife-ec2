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
    class Ec2EniList < Knife

      include Knife::Ec2Base

      banner "knife ec2 eni list (options)"

      def run
        validate!
        custom_warnings!

        eni_list = [
          ui.color("ID", :bold),
          ui.color("Status", :bold),
          ui.color("AZ", :bold),
          ui.color("Public IP", :bold),
          ui.color("Private IPs", :bold),
          ui.color("IPv6 IPs", :bold),
          ui.color("Subnet ID", :bold),
          ui.color("VPC ID", :bold)
        ].flatten.compact

        output_column_count = eni_list.length

        if config[:format] == "summary"
          eni_hash.each_pair do |_k, v|
            eni_list << v["network_interface_id"]
            eni_list << v["status"]
            eni_list << v["availability_zone"]
            eni_list << v["public_ip"].to_s # to_s since it might be nil
            eni_list << v["private_ips"].join(",")
            eni_list << v["ipv_6_addresses"].join(",")
            eni_list << v["subnet_id"]
            eni_list << v["vpc_id"]
          end
          puts ui.list(eni_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(eni_hash))
        end
      end

      private

      # build a hash of ENI we care about
      # @return [Hash]
      def eni_hash
        all_data = {}
        connection.describe_network_interfaces.first.network_interfaces.each do |eni|
          eni_data = {}
          %w{network_interface_id status mac_address availability_zone subnet_id vpc_id ipv_6_addresses}.each do |id|
            eni_data[id] = eni.send(id)
          end

          # parse out the 1+ private IPs from the associations in the
          # Aws::EC2::Types::NetworkInterfacePrivateIpAddress struct
          eni_data["private_ips"] = eni.private_ip_addresses.map { |a| a["private_ip_address"] }

          # grab the 1 public ip from the Aws::EC2::Types::NetworkInterfaceAssociation struct if it exists
          eni_data["public_ip"] = ( eni.association.nil? ? nil : eni.association["public_ip"] )

          all_data[eni_data["network_interface_id"]] = eni_data
        end
        all_data
      end
    end
  end
end
