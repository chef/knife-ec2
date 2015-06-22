#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2009-2011 Opscode, Inc.
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

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class Ec2ServerDelete < Knife

      include Knife::Ec2Base

      banner "knife ec2 server delete SERVER [SERVER] (options)"

      attr_reader :server

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the EC2 node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run

        validate!
        if @name_args.empty? && config[:chef_node_name]
          ui.info("no instance id is specific, trying to retrieve it from node name")
          instance_id = fetch_instance_id(config[:chef_node_name])
          @name_args << instance_id unless instance_id.nil?
        end

        @name_args.each do |instance_id|

          begin
            @server = connection.servers.get(instance_id)

            msg_pair('Instance ID', @server.id)
            msg_pair('Instance Name', @server.tags['Name'])
            msg_pair('Flavor', @server.flavor_id)
            msg_pair('Image', @server.image_id)
            msg_pair('Region', connection.instance_variable_get(:@region))
            msg_pair('Availability Zone', @server.availability_zone)
            msg_pair('Security Groups', @server.groups.join(', '))
            msg_pair('IAM Profile', iam_name_from_profile(@server.iam_instance_profile)) if @server.iam_instance_profile
            msg_pair('SSH Key', @server.key_name)
            msg_pair('Root Device Type', @server.root_device_type)
            msg_pair('Public DNS Name', @server.dns_name)
            msg_pair('Public IP Address', @server.public_ip_address)
            msg_pair('Private DNS Name', @server.private_dns_name)
            msg_pair('Private IP Address', @server.private_ip_address)

            puts '\n'
            confirm('Do you really want to delete this server')

            @server.destroy

            ui.warn("Deleted server #{@server.id}")

            if config[:purge]
              if config[:chef_node_name]
                thing_to_delete = config[:chef_node_name]
              else
                thing_to_delete = fetch_node_name(instance_id)
              end
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
            end
          rescue NoMethodError
            ui.error("Could not locate server '#{instance_id}'.  Please verify it was provisioned in the '#{locate_config_value(:region)}' region.")
          end
        end
      end

      def fetch_node_name(instance_id)
        result = query.search(:node,"ec2_instance_id:#{instance_id}")
        unless result.first.empty?
          result.first.first.name
        else
          instance_id
        end
      end

      def fetch_instance_id(name)
        result = query.search(:node,"name:#{name}")
        unless result.first.empty?
          node = result.first.first
          if node.attribute?('ec2')
            node['ec2']['instance_id']
          end
        end
      end

      def query
        @query ||= Chef::Search::Query.new
      end
    end
  end
end
