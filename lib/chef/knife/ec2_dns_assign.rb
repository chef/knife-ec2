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
require "ipaddress"

class Chef
  class Knife
    class Ec2DnsAssign < Knife

      include Knife::Ec2Base

      banner "knife ec2 dns record create (options)"

      option :zone_id,
        :short => "-z ZONE_ID",
        :long => "--zone_id ZONE_ID",
        :description => "Id of the zone to create a record in. Will be attempted to be determined based on the domain name.",
        :proc => Proc.new { |z| Chef::Config[:knife][:zone_id] = z }

      option :domain,
        :short => "-D DOMAIN",
        :long => "--domain DOMAIN",
        :description => "Domain name to assign."

      option :instance_id,
        :short => "-I ID",
        :long => "--instance-id ID",
        :description => "Instance Id to assign domain to."

      def run
        $stdout.sync = true

        validate!

        unless existing_record.nil?
          if existing_record.ip.one? { |ip| ip == instance_public_ip }
            ui.msg("Association already exists.")
            exit 0
          else
            ui.warn("The record for \"#{existing_record.name}\" already exists.")
            confirm("Would you like to replace it")
            existing_record.destroy
          end
        end

        record = zone.records.create(create_record_def)

        msg_pair("Id", record.id)
        msg_pair("Status", record.status)
        msg_pair("Ip", record.ip)
        msg_pair("Name", record.name)
        msg_pair("Type", record.type)
        msg_pair("TTL", record.ttl)
      end

      def zone
        @zone ||= begin
          return guess_zone if locate_config_value(:zone_id).nil?
          dns.zones.get(locate_config_value(:zone_id))
        end
      end

      def validate!

        super

        if zone.nil?
          ui.error("You have not provided a valid dns zone id or domain, please create a hosted zone before assigning a domain.")
          exit 1
        end

        if instance.nil?
          ui.error("You have not provided a valid instance id.")
          exit 1
        end

        if [:domain, :instance_id].any? { |key| config[key].nil? }
          ui.error("Instance id and domain are required for this operation.")
          exit 1
        end
      end

      def guess_zone
        dns.zones.find { |z| (config[:domain] + ".").index(z.domain) >= 0 }
      end

      def existing_record
        zone.records.find { |r| r.name == config[:domain] + "." }
      end

      def create_record_def
        { :ip => instance_public_ip,
          :type => record_type(instance_public_ip),
          :name => config[:domain] }
      end

      def record_type(public_ip)
        address = IPAddress(public_ip)
        if address.ipv4?
          "A"
        elsif address.ipv6?
          "AAAA"
        else
          error "Cannot recognize IP #{public_ip} as either IPv4 or IPv6 format"
        end
      end

      def instance_public_ip
        instance.public_ip_address
      end
      
      def instance
        @instance ||= compute.servers.get(config[:instance_id])
      end
    end
  end
end


