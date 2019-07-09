#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2009-2019 Chef Software, Inc.
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
    class Ec2ServerDelete < Knife

      include Knife::Ec2Base

      deps do
        # These two are needed for the '--purge' deletion case
        require "chef/node"
        require "chef/api_client"
      end

      banner "knife ec2 server delete SERVER [SERVER] (options)"

      attr_reader :server

      option :dry_run,
        long: "--dry-run",
        short: "-n",
        boolean: true,
        default: false,
        description: "Don't take action, only print what would happen."

      option :purge,
        short: "-P",
        long: "--purge",
        boolean: true,
        default: false,
        description: "Destroy corresponding node and client on the Chef Server, in addition to destroying the EC2 node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        short: "-N NAME",
        long: "--node-name NAME",
        description: "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        object = klass.load(name)
        object.destroy unless config[:dry_run]
        ui.warn("Deleted #{type_name} #{name}")
      rescue Net::HTTPServerException
        ui.warn("Could not find a #{type_name} named #{name} to delete!")
      end

      def run
        validate_aws_config!
        validate_instances!

        server_hashes.each do |h|
          instance_id = h["instance_id"]
          msg_pair("Instance ID", instance_id)
          msg_pair("Instance Name", h["name"])
          msg_pair("Flavor", h["instance_type"])
          msg_pair("Image", h["image_id"])
          msg_pair("Region", fetch_region)
          msg_pair("Availability Zone", h["az"])
          msg_pair("Security Groups", h["security_groups"])
          msg_pair("IAM Profile", h["iam_instance_profile"])
          msg_pair("SSH Key", h["key_name"])
          msg_pair("Root Device Type", h["root_device_type"])
          msg_pair("Public DNS Name", h["public_dns_name"])
          msg_pair("Public IP Address", h["public_ip_address"])
          msg_pair("Private DNS Name", h["private_dns_name"])
          msg_pair("Private IP Address", h["private_ip_address"])

          puts "\n"
          confirm("Do you really want to delete this server")

          delete_instance(instance_id) unless config[:dry_run]

          ui.warn("Deleted server #{instance_id}")

          if config[:purge]
            node_name = config[:chef_node_name] || fetch_node_name(instance_id)
            destroy_item(Chef::Node, node_name, "node")
            destroy_item(Chef::ApiClient, node_name, "client")
          else
            ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
          end
          puts "\n"
        end
      end

      # @return [String]
      def fetch_node_name(instance_id)
        result = query.search(:node, "ec2_instance_id:#{instance_id}")
        unless result.first.empty?
          result.first.first.name
        else
          instance_id
        end
      end

      # @return [String]
      def fetch_instance_id(name)
        result = query.search(:node, "name:#{name}")
        unless result.first.empty?
          node = result.first.first
          if node.attribute?("ec2")
            node["ec2"]["instance_id"]
          end
        end
      end

      # @return [Chef::Search::Query]
      def query
        @query ||= Chef::Search::Query.new
      end

      private

      # @return [Array<Hash>]
      def server_hashes
        all_data = []

        servers_list = ec2_connection.describe_instances({
          instance_ids: @name_args,
        })

        servers_list.reservations.each do |i|
          server_data = {}
          %w{image_id instance_id instance_type key_name root_device_type public_ip_address private_ip_address private_dns_name public_dns_name}.each do |id|
            server_data[id] = i.instances[0].send(id)
          end

          server_data["name"] = i.instances[0].tags[0].value
          server_data["az"] = i.instances[0].placement.availability_zone
          server_data["iam_instance_profile"] = ( i.instances[0].iam_instance_profile.nil? ? nil : i.instances[0].iam_instance_profile.arn[%r{instance-profile/(.*)}] )
          server_data["security_groups"] = i.instances[0].security_groups.map(&:group_name).join(", ")

          all_data << server_data
        end
        all_data
      end

      # Delete the server instance
      def delete_instance(instance_id)
        return nil unless instance_id || instance_id.is_a?(String)

        ec2_connection.terminate_instances({
          instance_ids: [
            instance_id,
          ],
        })
      end

      # If SERVER instance id not provided then check chef_name_tag and fetch the node
      # And if the node contains instance id then add it to the name args
      def validate_instances!
        if @name_args.empty?
          if config[:chef_node_name]
            ui.info("No instance id is specified, trying to retrieve it from node name")
            instance_id = fetch_instance_id(config[:chef_node_name])

            if instance_id.nil?
              ui.info("No instance id found.")
              exit 1
            else
              @name_args << instance_id
            end
          else
            ui.info("No instance id is specified.")
            exit 1
          end
        end
      end
    end
  end
end
