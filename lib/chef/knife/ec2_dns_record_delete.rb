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
    class Ec2DnsRecordDelete < Knife

      include Knife::Ec2Base

      banner "knife ec2 dns record create (options)"

      option :zone_id,
        :short => "-z ZONE_ID",
        :long => "--zone_id ZONE_ID",
        :description => "Id of the zone to create a record in",
        :proc => Proc.new { |z| Chef::Config[:knife][:zone_id] = z }

      option :ip,
        :long => "--ip IP",
        :description => "Ip entry of the record"

      option :type,
        :long => "--type TYPE",
        :description => "Entry type"

      option :name,
        :long => "--name NAME",
        :description => "Entry name"

      def run
        $stdout.sync = true

        validate!

        matching_records.each do |record|
          msg_pair("Id", record.id)
          msg_pair("Status", record.status)
          msg_pair("Ip", record.ip)
          msg_pair("Name", record.name)
          msg_pair("Type", record.type)
          msg_pair("TTL", record.ttl)

          puts "\n"
          confirm("Do you really want to delete this record")

          record.destroy

          ui.warn("Record deleted")
        end
      end

      def zone
        @zone ||= dns.zones.get(locate_config_value(:zone_id))
      end
      
      def matching_records
        zone.records.all.find_all do |record|
          searched_attributes.all? { |key| record.send(key) == config[key] }
        end
      end

      def searched_attributes
        @searched_attributes ||= begin
          config[:ip] = [*config[:ip]] unless config[:ip].nil?
          config[:name] = config[:name] + "." unless config[:name].nil?

          [:ip, :type, :name].find_all do |key|
            !config[key].nil?
          end
        end
      end

      def validate!

        super([:zone_id, :aws_ssh_key_id, :aws_access_key_id, :aws_secret_access_key])

        if zone.nil?
          ui.error("You have not provided a valid dns zone id.")
          exit 1
        end

        if matching_records.size == 0
          ui.error("No records matched your search criteria, exiting.")
          exit 1
        end
      end
    end
  end
end


