#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/server/list_command'
require 'chef/knife/ec2_helpers'
require 'chef/knife/cloud/ec2_service_options'
require 'chef/knife/cloud/server/list_options'

class Chef
  class Knife
    class Cloud
      class Ec2ServerList < ServerListCommand
        include Ec2Helpers
        include Ec2ServiceOptions
        include ServerListOptions

        banner "knife ec2 server list (options)"

        option :az,
          :long => "--availability-zone",
          :boolean => true,
          :default => false,
          :description => "Show availability zones"

        def before_exec_command
          #set columns_with_info map
          @columns_with_info = [
          {:label => 'Instance ID', :key => 'id'},
          {:label => 'Name', :key => 'tags', :value_callback => method(:get_instance_name)},
          {:label => 'Public IP', :key => 'public_ip_address'},
          {:label => 'Private IP', :key => 'private_ip_address'},
          {:label => 'Flavor', :key => 'flavor_id', :value_callback => method(:fcolor)},
          {:label => 'Image', :key => 'image_id'},
          {:label => 'SSH Key', :key => 'key_name'},
          {:label => 'State', :key => 'state', :value_callback => method(:format_server_state)},
          {:label => 'IAM Profile', :key => 'iam_instance_profile'}
        ]
          @columns_with_info << {:label => 'AZ', :key => 'availability_zone', :value_callback => method(:azcolor)} if config[:az]
          super
        end

        def get_instance_name(tags)
          return tags['Name'] if tags['Name']
        end

        def fcolor(flavor)
          fcolor =  case flavor
                    when "t1.micro"
                      :blue
                    when "m1.small"
                      :magenta
                    when "m1.medium"
                      :cyan
                    when "m1.large"
                      :green
                    when "m1.xlarge"
                      :red
                    end
          ui.color(flavor, fcolor)
        end

        def azcolor(az)
          color = case az
                  when /a$/
                    :blue
                  when /b$/
                    :green
                  when /c$/
                    :red
                  when /d$/
                    :magenta
                  else
                    :cyan
                  end
          ui.color(az, color)
        end  
      end
    end
  end
end
