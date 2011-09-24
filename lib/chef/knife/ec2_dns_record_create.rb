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
    class Ec2DnsRecordCreate < Knife

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
        :description => "Entry type",
        :default => "CNAME"

      option :name,
        :long => "--name NAME",
        :description => "Entry name"

      def run
        $stdout.sync = true

        validate!

        record = zone.records.create(create_record_def)

        msg_pair("Id", record.id)
        msg_pair("Status", record.status)
        msg_pair("Ip", record.ip)
        msg_pair("Name", record.name)
        msg_pair("Type", record.type)
        msg_pair("TTL", record.ttl)
      end

      def create_record_def
        { :ip => config[:ip],
          :type => config[:type],
          :name => config[:name] }
      end

      def zone
        @zone ||= dns.zones.get(locate_config_value(:zone_id))
      end

      def validate!

        super([:zone_id, :aws_ssh_key_id, :aws_access_key_id, :aws_secret_access_key])

        if zone.nil?
          ui.error("You have not provided a valid dns zone id.")
          exit 1
        end

        if [:ip, :name].any? { |key| config[key].nil? }
          ui.error("Record ip and name are required, please specify them using appropriate command options. Record type defaults to \"CNAME\" and can be overriden using --type option")
          exit 1
        end
      end
    end
  end
end


