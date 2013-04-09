#
# Author:: Radek Gruchalski (<radek@gruchalski.com>)
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
    class Ec2ServerStop < Knife

      include Knife::Ec2Base

      banner "knife ec2 server stop (options)"

      option :instances,
        :short => "-i INSTANCE_ID,INSTANCE_ID",
        :long => "--ids INSTANCE_ID,INSTANCE_ID",
        :description => "List of instance ids"

      option :tags,
        :short => "-t TAG1=VALUE,TAG2=PATTERN*",
        :long => "--tags TAG1=VALUE,TAG2=PATTERN*",
        :description => "List of tags to filter by"

      def run
        
        server_ids = []
        tags = {}
        if config[:instances]
          server_ids = config[:instances].split(",")
        end
        if config[:tags]
          config[:tags].split(",").collect do |tag|
            key_val = tag.split("=")
            tags[key_val[0].downcase] = key_val[1]
          end
          
          connection.servers.all.each do |server|
            server.tags.each do |name,value|
              if tags.has_key?(name.downcase)
                if tags[name.downcase].end_with?("*")
                  if value.start_with?( tags[name.downcase][0 .. tags[name.downcase].length-2] )
                    server_ids.push( server.id )
                  end
                else
                  if tags[name.downcase] == value
                    server_ids.push( server.id )
                  end
                end
              end
            end
            
          end
          
        end
        
        if server_ids.empty?
          ui.error "No servers to stop."
          exit 1
        end
        
        # verify that server ids actually exist:
        server_ids.each do |server_id|
          if connection.servers.get(server_id).nil?
            ui.error "Server #{server_id} does not exist. Please verify your list."
            exit 1
          end
        end
        
        ui.info "You have asked me to stop the following servers:"
        
        server_list = [
          ui.color('Instance ID', :bold),
          ui.color("Name", :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('SSH Key', :bold),
          ui.color('Security Groups', :bold),
          ui.color("Tags", :bold),
          ui.color('State', :bold)
          
        ].flatten.compact

        output_column_count = server_list.length
        
        connection.servers.all.each do |server|
          
          if server_ids.include?( server.id )
            server_list << server.id.to_s
            server_list << server.tags["Name"].to_s
            server_list << server.public_ip_address.to_s
            server_list << server.private_ip_address.to_s
            server_list << server.flavor_id.to_s
            server_list << server.image_id.to_s
            server_list << server.key_name.to_s
            server_list << server.groups.join(", ")
            server_list << server.tags.to_s
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
          
        end
        
        puts ui.list(server_list, :uneven_columns_across, output_column_count)
        
        confirm("Are you sure you want to continue")
        
        server_ids.each do |server_id|
          ui.info "Issuing stop request for #{server_id}."
          connection.servers.get( server_id ).stop(true)
        end

      end
    end
  end
end
