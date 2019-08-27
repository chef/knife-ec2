#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2010-2019 Chef Software, Inc.
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

require "chef/knife/ec2_base"

class Chef
  class Knife
    class Ec2ServerList < Knife

      include Knife::Ec2Base

      banner "knife ec2 server list (options)"

      option :name,
        short: "-n",
        long: "--no-name",
        boolean: true,
        default: true,
        description: "Do not display name tag in output"

      option :iamprofile,
        short: "-i",
        long: "--iam-profile",
        boolean: true,
        default: false,
        description: "Show the iam profile"

      option :az,
        short: "-a",
        long: "--availability-zone",
        boolean: true,
        default: false,
        description: "Show availability zones"

      option :tags,
        short: "-t TAG1,TAG2",
        long: "--tags TAG1,TAG2",
        description: "List of tags to output"

      # @return [Symbol]
      def azcolor(az)
        case az
        when /a$/
          color = :blue
        when /b$/
          color = :green
        when /c$/
          color = :red
        when /d$/
          color = :magenta
        when /e$/
          color = :yellow
        else
          color = :cyan
        end
      end

      # @return [Symbol]
      def state_color(state)
        case state
        when "shutting-down", "terminated", "stopping", "stopped"
          :red
        when "pending"
          :yellow
        else
          :green
        end
      end

      def run
        $stdout.sync = true

        validate_aws_config!

        servers_list = [
          ui.color("Instance ID", :bold),

          if config[:name]
            ui.color("Name", :bold)
          end,

          ui.color("Public IP", :bold),
          ui.color("Private IP", :bold),
          ui.color("Flavor", :bold),

          if config[:az]
            ui.color("AZ", :bold)
          end,

          ui.color("Image", :bold),
          ui.color("SSH Key", :bold),
          ui.color("Security Groups", :bold),

          if config[:tags]
            config[:tags].split(",").collect do |tag_name|
              ui.color("Tag:#{tag_name}", :bold)
            end
          end,

          if config[:iamprofile]
            ui.color("IAM Profile", :bold)
          end,

          ui.color("State", :bold),
        ].flatten.compact

        output_column_count = servers_list.length

        if !config[:region] && Chef::Config[:knife][:region].nil?
          ui.warn "No region was specified in knife.rb/config.rb or as an argument. The default region, us-east-1, will be used:"
        end

        if config[:format] == "summary"
          server_hashes.each do |v|
            servers_list << v["instance_id"]
            servers_list << v["name"] if config[:name]
            servers_list << v["public_ip_address"]
            servers_list << v["private_ip_address"]
            servers_list << v["instance_type"]
            servers_list << ui.color(v["az"], azcolor(v["az"])) if config[:az]
            servers_list << v["image_id"]
            servers_list << v["key_name"]
            servers_list << v["security_groups"].join(",")
            if config[:tags]
              config[:tags].split(",").collect do |tag_name|
                servers_list << v["tags"].find { |tag| tag == tag_name }
              end
            end
            servers_list << v["iam_instance_profile"].to_s if config[:iamprofile] # may be nil
            servers_list << ui.color(v["state"], state_color(v["state"]))
          end
          puts ui.list(servers_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(server_hashes))
        end
      end

      private

      # @return [Array<Hash>]
      def server_hashes
        all_data = []
        ec2_connection.describe_instances.reservations.each do |i|
          server_data = {}
          %w{image_id instance_id instance_type key_name public_ip_address private_ip_address}.each do |id|
            server_data[id] = i.instances[0].send(id)
          end

          # dig into tags struct
          tags = extract_tags(i.instances[0].tags)

          if config[:name]
            server_data["name"] = tags[0]
          end

          if config[:az]
            server_data["az"] = i.instances[0].placement.availability_zone
          end

          server_data["iam_instance_profile"] = ( i.instances[0].iam_instance_profile.nil? ? nil : i.instances[0].iam_instance_profile.arn[%r{instance-profile/(.*)}] )

          server_data["state"] = i.instances[0].state.name

          if config[:tags]
            server_data["tags"] = tags
          end

          # dig into security_groups struct
          server_data["security_groups"] = i.instances[0].security_groups.map(&:group_name)

          all_data << server_data
        end
        all_data
      end

      # @return [Array<String>]
      def extract_tags(tags_struct)
        tags_struct.map(&:value)
      end
    end
  end
end
