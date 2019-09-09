#
# Author:: Piyush Awasthi (<piyush.awasthi@msystechnologies.com>)
# Copyright:: Copyright (c) 2017-2019 Chef Software, Inc.
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

require "chef/knife/ec2_base"

class Chef
  class Knife
    # == Overview
    #
    # This file provides the facility to display AMI list.
    #
    # == Owner
    # By default owner is aws-marketplace but you can specify following owner with the help of -o or --owner
    #   * self => Displays the list of AMIs created by the user
    #   * aws-marketplace => Displays all AMIs form trusted vendors like Ubuntu, Microsoft, SAP, Zend as well as many open source offering
    #   * micosoft => Displays only Microsoft vendor AMIs
    #
    # == Platform
    # By default all platform AMI's will display but you can filter your response
    # by specify the platform using -p or --platform
    #  * Valid Platform => ubuntu, debian, centos, fedora, rhel, nginx, turnkey, jumpbox, coreos, cisco
    #
    # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeImages.html]
    class Ec2AmiList < Knife
      include Knife::Ec2Base

      banner "knife ec2 ami list (options)"

      option :platform,
        short: "-p PLATFORM",
        long: "--platform PLATFORM",
        description: "Platform of the server",
        in: Chef::Knife::Ec2Base::VALID_PLATFORMS
      option :owner,
        short: "-o OWNER",
        long: "--owner OWNER",
        description: "The AMI owner. Default is aws-marketplace",
        default: "aws-marketplace",
        in: %w{self aws-marketplace microsoft}

      option :search,
        short: "-s SEARCH",
        long: "--search SEARCH",
        description: "Filter AMIs list as per search keywords."

      def run
        $stdout.sync = true

        validate_aws_config!
        custom_warnings!

        servers_list = [
          ui.color("AMI ID", :bold),
          ui.color("Platform", :bold),
          ui.color("Architecture", :bold),
          ui.color("Size", :bold),
          ui.color("Name", :bold),
          ui.color("Description", :bold),
        ].flatten.compact

        output_column_count = servers_list.length

        if config[:format] == "summary"
          ami_hashes.each_pair do |_k, v|
            servers_list << v["image_id"]
            servers_list << v["platform"]
            servers_list << v["architecture"]
            servers_list << v["size"]
            servers_list << v["name"]
            servers_list << v["description"]
          end
          puts ui.list(servers_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(ami_hashes))
        end
      end

      private

      def ami_hashes
        all_data = {}
        ec2_connection.describe_images(image_params).images.each do |v|
          v_data = {}
          if locate_config_value(:search)
            next unless v.description.downcase.include?(locate_config_value(:search).downcase)
          end

          %w{image_id platform description architecture}.each do |id|
            v_data[id] = v.send(id)
          end

          v_data["name"] = v.name.split(/\W+/).first
          v_data["size"] = v.block_device_mappings[0].ebs.volume_size.to_s
          all_data[v_data["image_id"]] = v_data
        end
        all_data
      end

      def image_params
        params = {}
        params["owners"] = [locate_config_value(:owner).to_s]

        filters = []
        if locate_config_value(:platform)
          filters << { name: "platform",
                       values: [locate_config_value(:platform)] }
        end

        # TODO: Need to find substring to match in the description
        # filters << { description: locate_config_value(:search) } if locate_config_value(:search)

        if filters.length > 0
          params["filters"] = filters
        end
        params
      end
    end
  end
end
