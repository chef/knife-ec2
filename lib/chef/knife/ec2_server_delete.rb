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
    class Ec2ServerDelete < Knife

      deps do
        require 'fog'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife ec2 server delete SERVER [SERVER] (options)"

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
        :long => "--fog-credentials",
        :description => "Load the specified set of fog credentials from your fog authentication file"

      option :region,
        :long => "--region REGION",
        :description => "Your AWS region",
        :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }

      def run
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

        @name_args.each do |instance_id|
          server = connection.servers.get(instance_id)

          msg("Instance ID", server.id)
          msg("Flavor", server.flavor_id)
          msg("Image", server.image_id)
          msg("Availability Zone", server.availability_zone)
          msg("Security Groups", server.groups.join(", "))
          msg("SSH Key", server.key_name)
          msg("Public DNS Name", server.dns_name)
          msg("Public IP Address", server.public_ip_address)
          msg("Private DNS Name", server.private_dns_name)
          msg("Private IP Address", server.private_ip_address)

          puts "\n"
          confirm("Do you really want to delete this server")

          server.destroy

          ui.warn("Deleted server #{server.id}")
        end
      end

      def msg(label, value)
        if value && !value.empty?
          puts "#{ui.color(label, :cyan)}: #{value}"
        end
      end

    end
  end
end

