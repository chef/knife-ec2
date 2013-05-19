#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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
    class Ec2Sshconfig < Knife

      include Knife::Ec2Base

      banner "knife ec2 sshconfig (options)"

      option :tags,
        :short => "-t TAG1,TAG2",
        :long => "--tags TAG1,TAG2",
        :description => "only include servers with this tag"

      option :replace,
        :short => "-r",
        :long => "--replace",
        :description => "Replace all unqualifed aliases"


      def run
        $stdout.sync = true
        validate!      
        connection.servers.all.each do |server|
          name = server.tags["Name"].to_s
          next unless name and server.dns_name
          puts "host #{name}"
          puts "   hostname #{server.dns_name}"
        end
      end
    end
  end
end
