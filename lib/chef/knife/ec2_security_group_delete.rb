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
    class Ec2SecurityGroupDelete < Knife

      include Knife::Ec2Base

      banner "knife ec2 security group delete (options)"
      
      option :security_group_name,
        :short => "-G GROUPID",
        :long => "--security-group-id GROUPID",
        :description => "Security group id to delete"
      
      def run
        validate!
        @security_group = connection.security_groups.get_by_id( security_group_id )
        @security_group.destroy
      end
      
      def security_group_id
        locate_config_value(:security_group_id)
      end
      
      def validate!
        super()
        
        if security_group_id.nil?
          ui.error("Security group id must be given")
          exit 1
        else
          @target_group = connection.security_groups.get_by_id(security_group_id)
          if @target_group.nil?
             ui.error("Security group #{security_group_id} does not exist.")
             exit 1
           end
        end
        
      end
      
    end
  end
end
