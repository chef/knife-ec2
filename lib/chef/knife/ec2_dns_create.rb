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
        :proc => Proc.new { |d| Chef::Config[:knife][:domain] = d }

      option :email,
        :short => "-e EMAIL",
        :long => "--email EMAIL",
        :description => "Email to be used when creating a new dns zone"

      option :caller_ref,
        :long => "--caller-ref \"CALLER REF\"",
        :description => "Caller reference"

      option :description,
        :long => "--description \"DESCRIPTION\"",
        :description => "Description"

      def run
        $stdout.sync = true

        validate!

        zone = dns.zones.create(create_zone_def)
        
        msg_pair("Zone Id", zone.id)
        msg_pair("Domain", zone.domain)
        msg_pair("Nameservers", zone.nameservers.to_s)
        msg_pair("Caller Reference", zone.caller_reference)
        msg_pair("Description", zone.description.to_s)
        msg_pair("Change Info", zone.change_info.to_s)
      end

      def create_zone_def
        zone_def = {
          :domain => locate_config_value(:domain)
        }

        [:email, :caller_ref, :description].each do |key|
          zone_def[key] = config[key] if config[key]
        end

        zone_def
      end

      def validate!

        super([:domain, :aws_ssh_key_id, :aws_access_key_id, :aws_secret_access_key])
      end
    end
  end
end


