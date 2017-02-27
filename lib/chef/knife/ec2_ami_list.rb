#
# Author:: Piyush Awasthi (<piyush.awasthi@msystechnologies.com>)
# Copyright:: Copyright (c) 2017 Chef Software, Inc.
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
    class Ec2AmiList < Knife

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

      include Knife::Ec2Base

      banner "knife ec2 ami list (options)"

      option :platform,
        :short => "-p PLATFORM",
        :long => "--platform PLATFORM",
        :description => "Platform of the server. Allowed values are windows, ubuntu, debian, centos, fedora, rhel, nginx, turnkey, jumpbox, coreos, cisco, amazon, nessus"

      option :owner,
        :short => "-o OWNER",
        :long => "--owner OWNER",
        :description => "The server owner (self, aws-marketplace, microsoft). Default is aws-marketplace"

      option :search,
        :short => "-s SEARCH",
        :long => "--search SEARCH",
        :description => "Filter AMIs list as per search keywords."

      def run
        $stdout.sync = true

        validate!
        custom_warnings!

        server_list = [
          ui.color("AMI ID", :bold),
          ui.color("Platform", :bold),
          ui.color("Architecture", :bold),
          ui.color("Size", :bold),
          ui.color("Name", :bold),
          ui.color("Description", :bold)
        ].flatten.compact

        output_column_count = server_list.length
        begin
          owner = locate_config_value(:owner) || "aws-marketplace"
          servers = connection.describe_images({"Owner"=>"#{owner}"}) # aws-marketplace, microsoft
        rescue Exception => api_error
          raise api_error
        end

        servers.body["imagesSet"].each do |server|
          server["platform"] = find_server_platform(server["name"]) unless server["platform"]

          if (locate_config_value(:platform) && locate_config_value(:search))
            locate_config_value(:search).downcase!
            if (server["description"] && server["platform"] == locate_config_value(:platform) && server["description"].downcase.include?(locate_config_value(:search)))
              server_list += get_server_list(server)
            end
          elsif locate_config_value(:platform)
            if server["platform"] == locate_config_value(:platform)
              server_list += get_server_list(server)
            end
          elsif locate_config_value(:search)
            locate_config_value(:search).downcase!
            if (server["description"] && server["description"].downcase.include?(locate_config_value(:search)))
              server_list += get_server_list(server)
            end
          else
            server_list += get_server_list(server)
          end
        end
        puts ui.list(server_list, :uneven_columns_across, output_column_count)
      end

    private

      def get_server_list(server)
        server_list = []
        server_list << server["imageId"]
        server_list << server["platform"]
        server_list << server["architecture"]
        server_list << server["blockDeviceMapping"].first["volumeSize"].to_s
        server_list << server["name"].split(/\W+/).first
        server_list << server["description"]
      end
    end
  end
end
