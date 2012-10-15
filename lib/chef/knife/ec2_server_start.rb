#
# Author:: Chirag Jog (<chirag.jog@gmail.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
    class Ec2ServerStart < Knife

      include Knife::Ec2Base

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server start SERVER (options)"

      attr_accessor :initial_sleep_delay

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      def validate!

        if @name_args.size == 0
          ui.error("You have not provided a server name.")
          exit 1
        end

      end

      def run
        $stdout.sync = true
        validate!
        @name_args.each do |instance_id|
          begin
              server = connection.servers.get(instance_id)
              msg_pair("Instance ID", server.id)
              msg_pair("Flavor", server.flavor_id)
              msg_pair("Image", server.image_id)
              puts "\n"
              confirm("Do you really want to start this server [#{server.id}]?")
              server.start
              msg_pair("Started server", server.id)
          rescue NoMethodError
            ui.error ("Could not locate server '#{instance_id}'. Please verify it was provisioned in the '#{locate_config_value(:region)}' region.")
          end
      end   
     end 
    end
  end
end
