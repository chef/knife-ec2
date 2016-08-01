#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2010-2015 Chef Software, Inc.
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
    class Ec2ServerList < Knife

      include Knife::Ec2Base

      banner "knife ec2 server list (options)"

      option :name,
        :short => "-n",
        :long => "--no-name",
        :boolean => true,
        :default => true,
        :description => "Do not display name tag in output"

      option :az,
        :short => "-z",
        :long => "--availability-zone",
        :boolean => true,
        :default => false,
        :description => "Show availability zones"

      option :tags,
        :short => "-t TAG1,TAG2",
        :long => "--tags TAG1,TAG2",
        :description => "List of tags to output"

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
        else
          color = :cyan
        end
      end

      def run
        $stdout.sync = true

        validate!

        server_list = [
          ui.color('Instance ID', :bold),

          if config[:name]
            ui.color("Name", :bold)
          end,

          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),

          if config[:az]
            ui.color('AZ', :bold)
          end,

          ui.color('Image', :bold),
          ui.color('SSH Key', :bold),
          ui.color('Security Groups', :bold),

          if config[:tags]
            config[:tags].split(",").collect do |tag_name|
              ui.color("Tag:#{tag_name}", :bold)
            end
          end,

          ui.color('IAM Profile', :bold),
          ui.color('State', :bold)
        ].flatten.compact

        output_column_count = server_list.length

        if !config[:region] && Chef::Config[:knife][:region].nil?
          ui.warn "No region was specified in knife.rb or as an argument. The default region, us-east-1, will be used:"
        end

        servers = connection.servers
        if (config[:format] == 'summary')
          servers.each do |server|
            server_list << server.id.to_s

            if config[:name]
              server_list << server.tags["Name"].to_s
            end

            server_list << server.public_ip_address.to_s
            server_list << server.private_ip_address.to_s
            server_list << server.flavor_id.to_s

            if config[:az]
              server_list << ui.color(
                                  server.availability_zone.to_s,
                                  azcolor(server.availability_zone.to_s)
                                )
            end

            server_list << server.image_id.to_s
            server_list << server.key_name.to_s
            server_list << server.groups.join(", ")

            if config[:tags]
              config[:tags].split(",").each do |tag_name|
                server_list << server.tags[tag_name].to_s
              end
            end

            server_list << iam_name_from_profile(server.iam_instance_profile)

            server_list << begin
              state = server.state.to_s.downcase
              case state
              when 'shutting-down','terminated','stopping','stopped'
                ui.color(state, :red)
              when 'pending'
                ui.color(state, :yellow)
              else
                ui.color(state, :green)
              end
            end
          end

          puts ui.list(server_list, :uneven_columns_across, output_column_count)
        else
          output(format_for_display(servers))
        end
      end
    end
  end
end
