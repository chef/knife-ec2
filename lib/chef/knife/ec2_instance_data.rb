#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class Ec2InstanceData < Knife
      
      deps do
        require 'chef/json_compat'
      end

      banner "knife ec2 instance data (options)"

      option :edit,
        :long => "--edit",
        :description => "Edit the instance data"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      def run
        data = {
          "chef_server" => Chef::Config[:chef_server_url],
          "validation_client_name" => Chef::Config[:validation_client_name],
          "validation_key" => IO.read(Chef::Config[:validation_key]),
          "attributes" => { "run_list" => config[:run_list] }
        }
        data = edit_data(data) if config[:edit]
        ui.output(data)
      end
    end
  end
end

