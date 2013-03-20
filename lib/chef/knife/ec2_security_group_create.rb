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
    class Ec2SecurityGroupCreate < Knife

      include Knife::Ec2Base

      banner "knife ec2 security group create (options)"
      
      option :security_group_name,
        :short => "-N NAME",
        :long => "--security-group-name NAME",
        :description => "Security group name"
        
      option :security_group_description,
        :short => "-D DESCRIPTION",
        :long => "--security-group-description DESCRIPTION",
        :description => "Security group description"
      
      def run
        
        validate!
        
        @security_group = connection.security_groups.create({
          :name => locate_config_value(:security_group_name),
          :description => locate_config_value(:security_group_description)
        })
        
        msg_pair("Name", @security_group.name)
        msg_pair("Description", @security_group.description)
        msg_pair("Group ID", @security_group.group_id)
        
      end
      
    end
  end
end
