#
# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/server/delete_options'
require 'chef/knife/cloud/server/delete_command'
require 'chef/knife/cloud/ec2_service'
require 'chef/knife/cloud/ec2_service_options'
require 'chef/knife/ec2_helpers'

class Chef
  class Knife
    class Cloud
      class Ec2ServerDelete < ServerDeleteCommand
        include ServerDeleteOptions
        include Ec2ServiceOptions
        include Ec2Helpers

        banner "knife ec2 server delete SERVER [SERVER] (options)"

        # We can get ec2 instance_id from chef node name and vice-versa
        def execute_command
          if @name_args.empty? && config[:chef_node_name]
            ui.info("No Instance Id is specified, trying to retrieve it from node name")
            instance_id = fetch_instance_id(config[:chef_node_name])
            @name_args << instance_id unless instance_id.nil?
          end
          super
        end

        def delete_from_chef(server_name)
          if config[:purge]
            if config[:chef_node_name]
              thing_to_delete = config[:chef_node_name]
            else
              thing_to_delete = fetch_node_name(server_name)
            end
          end
          thing_to_delete ||= server_name
          super(thing_to_delete)
        end

        def fetch_node_name(instance_id)
          result = query.search(:node, "ec2_instance_id:#{instance_id}")

          unless result.first.empty?
            result.first.first.name
          else
            instance_id
          end
        end

        def fetch_instance_id(name)
          result = query.search(:node, "name:#{name}")

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
end
