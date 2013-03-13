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
require 'netaddr'

class Chef
  class Knife
    class Ec2SecurityGroupRuleAdd < Knife

      include Knife::Ec2Base

      banner "knife ec2 security group create (options)"

      option :security_group_id,
        :short => "-G GROUPID",
        :long => "--security-group-id GROUPID",
        :description => "Security group id"
      
      option :security_group_rule_protocol,
        :short => "-P PROTOCOL",
        :long => "--securoty-group-rule-protocol PROTOCOL",
        :description => "Security group rule protocol"
        
      option :security_group_rule_cidr,
        :short => "-C CIDR",
        :long => "---security-group-rule-cidr DESCRIPTION",
        :description => "Security group rule cidr"
        
      option :security_group_rule_target_group,
        :short => "-T GROUPID",
        :long => "---security-group-rule-group GROUPID",
        :description => "Security group rule target group"
        
      option :security_group_rule_range,
        :short => "-R RANGE",
        :long => "---security-group-rule-port-range RANGE",
        :description => "Security group rule port range, i.e. 3000 or 3000-4000"
      
      def run
        
        validate!
        
        opts = { :ip_protocol => security_group_rule_protocol }
        if security_group_rule_cidr.nil? and security_group_rule_target_group.nil?
          opts[:cidr_ip] = "0.0.0.0/0"
        elsif !security_group_rule_cidr.nil? and !security_group_rule_target_group.nil?
          # CIDR will take priority
          opts[:cidr_ip] = security_group_rule_cidr
        else
          if !security_group_rule_target_group.nil?
            opts[:group] = security_group_rule_target_group
          else
            opts[:cidr_ip] = security_group_rule_cidr
          end
        end
        
        @security_group = connection.security_groups.get_by_id( security_group_id )
        @security_group.authorize_port_range(port_range, opts)
        
        msg_pair("Name", @security_group.name)
        msg_pair("Description", @security_group.description)
        msg_pair("Group ID", @security_group.group_id)
        
      end
      
      def port_range
        if security_group_rule_range.count("-") == 0
          value = security_group_rule_range.to_i
          Range.new(value,value)
        elsif security_group_rule_range.count("-") == 1
          items = security_group_rule_range.split(/-/)
          min = items.first.to_i
          max = items.last.to_i
          Range.new(min,max)
        else
          Range.new(0,0)
        end
      end
      
      def security_group_id
        locate_config_value(:security_group_id)
      end
      
      def security_group_rule_protocol
        locate_config_value(:security_group_rule_protocol)
      end
      
      def security_group_rule_cidr
        locate_config_value(:security_group_rule_cidr)
      end
      
      def security_group_rule_target_group
        locate_config_value(:security_group_rule_target_group)
      end
      
      def security_group_rule_range
        locate_config_value(:security_group_rule_range)
      end
      
      def validate!
        
        super()
        
        if security_group_id.nil?
          ui.error("Security group id must be given")
          exit 1
        else
          @target_group = connection.security_groups.get_by_id(security_group_id)
          if @target_group.nil?
             ui.error("Target security group does not exist.")
             exit 1
           end
        end
        
        if security_group_rule_protocol.nil?
          ui.error("Security group protocol must be given.")
          exit 1
        else
          if (security_group_rule_protocol <=> "tcp") != 0 and (security_group_rule_protocol <=> "udp") != 0 and (security_group_rule_protocol <=> "icmp") != 0
            ui.error("Security group protocol must be either tcp, udp or icmp.")
            exit 1
          end
        end
        
        if !security_group_rule_cidr.nil?
          NetAddr::CIDR.create(security_group_rule_cidr)
          if (NetAddr::CIDR.create(security_group_rule_cidr) rescue nil).nil?
            ui.error("CIDR string is not a valid CIDR.")
            exit 1
          end
        end
        
        if !security_group_rule_target_group.nil?
           @target_group = connection.security_groups.get_by_id(security_group_rule_target_group)
           if @target_group.nil?
             ui.error("Target security group does not exist.")
             exit 1
           end
        end
        
        if security_group_rule_range.nil?
          ui.error("Port range is required.")
          exit 1
        else
          if security_group_rule_range.count("-") == 0
            if security_group_rule_range.to_i.to_s != security_group_rule_range
              ui.error("Port must be an integer.")
              exit 1
            else
              if security_group_rule_range.to_i > 65535
                ui.error("Invalid port number.")
                exit 1
              end
            end
          elsif security_group_rule_range.count("-") == 1
            items = security_group_rule_range.split(/-/)
            if items.first.to_i.to_s != items.first
              ui.error("Range is invalid.")
              exit 1
            end
            if items.last.to_i.to_s != items.last
              ui.error("Range is invalid.")
              exit 1
            end
            
            if items.first.to_i > 65535
              ui.error("Invalid start of the port range.")
              exit 1
            end
            if items.last.to_i > 65535
              ui.error("Invalid end of the port range.")
              exit 1
            end
            if items.first.to_i > items.last.to_i
              ui.error("Beginning of the range higher than end.")
              exit 1
            end
            
          else
            ui.error("Port range is invalid.")
            exit 1
          end
        end
        
      end
      
    end
  end
end
