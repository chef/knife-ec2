#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Bulat Shakirzyanov (<mallluhuct@gmail.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
    class Ec2DnsCreate < Knife

      include Knife::Ec2Base

      banner "knife ec2 dns create (options)"

      option :domain,
        :short => "-d DOMAIN",
        :long => "--domain DOMAIN",
        :description => "Domain (without http or www) to be used for new dns zone",
        :proc => Proc.new { |key| Chef::Config[:knife][:domain] = key }

      option :email,
        :short => "-e EMAIL",
        :long => "--email EMAIL",
        :description => "Email to be used when creating a new dns zone",
        :proc => Proc.new { |key| Chef::Config[:knife][:email] = key }

      option :caller_ref,
        :long => "--caller-ref CALLER REFERENCE",
        :description => "Caller reference"

      option :description,
        :long => "--description DESCRIPTION",
        :description => "Description"

      def run
        $stdout.sync = true

        validate!

        dns.zones.create(create_zone_def)
      end

      def create_zone_def
        zone_def = {
          :domain => locate_config_value(:domain)
        }
        zone_def[:email] = locate_config_value(:email) if locate_config_value(:email)
        zone_def[:caller_ref] = config[:caller_ref] if config[:caller_ref]
        zone_def[:description] = config[:description] if config[:description]

        zone_def
      end

      def validate!

        super([:domain, :aws_ssh_key_id, :aws_access_key_id, :aws_secret_access_key])
      end
    end
  end
end


