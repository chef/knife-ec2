#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
    class Ec2ServerList < Knife

      deps do
        require 'fog'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife ec2 server list (options)"

      option :aws_access_key_id,
        :short => "-A ID",
        :long => "--aws-access-key-id KEY",
        :description => "Your AWS Access Key ID",
        :proc => Proc.new { |key| Chef::Config[:knife][:aws_access_key_id] = key }

      option :aws_secret_access_key,
        :short => "-K SECRET",
        :long => "--aws-secret-access-key SECRET",
        :description => "Your AWS API Secret Access Key",
        :proc => Proc.new { |key| Chef::Config[:knife][:aws_secret_access_key] = key }

      option :fog_credential_name,
        :long => "--fog-credentials CREDENTIALS",
        :description => "Load the specified set of fog credentials from your fog authentication file"

      option :region,
        :long => "--region REGION",
        :description => "Your AWS region",
        :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }

      def run
        $stdout.sync = true

        if config[:fog_credential_name]
          Fog.credential = config[:fog_credential_name].to_sym
          connection = Fog::Compute.new(
            :provider => 'AWS',
            :region => Chef::Config[:knife][:region] || config[:region] || Fog.credentials[:region]
          )
        else
          connection = Fog::Compute.new(
            :provider => 'AWS',
            :aws_access_key_id => Chef::Config[:knife][:aws_access_key_id],
            :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
            :region => Chef::Config[:knife][:region] || config[:region]
          )
        end

        server_list = [
          ui.color('Instance ID', :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('Security Groups', :bold),
          ui.color('State', :bold)
        ]
        connection.servers.all.each do |server|
          server_list << server.id.to_s
          server_list << (server.public_ip_address == nil ? "" : server.public_ip_address)
          server_list << (server.private_ip_address == nil ? "" : server.private_ip_address)
          server_list << (server.flavor_id == nil ? "" : server.flavor_id)
          server_list << (server.image_id == nil ? "" : server.image_id)
          server_list << server.groups.join(", ")
          server_list << (server.state == nil ? "" : server.state)
        end
        puts ui.list(server_list, :columns_across, 7)

      end
    end
  end
end


