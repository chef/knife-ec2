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

        option :name,
          :short => "-n",
          :long => "--no-name",
          :boolean => true,
          :default => true,
          :description => "Do not display name tag in output"

        option :az,
          :long => "--availability-zone",
          :boolean => true,
          :default => false,
          :description => "Show availability zones"

        option :tags,
          :short => "-t TAG1,TAG2",
          :long => "--tags TAG1,TAG2",
          :description => "List of tags to output"

        def before_exec_command
          #set columns_with_info map
          @columns_with_info = [
            {:label => 'Instance ID', :key => 'id'},
            if config[:name]
              {:label => 'Name', :key => 'tags', :value_callback => method(:get_instance_name)}
            end ,
            {:label => 'Public IP', :key => 'public_ip_address'},
            {:label => 'Private IP', :key => 'private_ip_address'},
            {:label => 'Flavor', :key => 'flavor_id', :value_callback => method(:fcolor)},
            {:label => 'Image', :key => 'image_id'},
            {:label => 'SSH Key', :key => 'key_name'},
            {:label => 'Security Groups', :key => 'groups', :value_callback => method(:get_security_groups)},
            {:label => 'State', :key => 'state', :value_callback => method(:format_server_state)},
            {:label => 'IAM Profile', :key => 'iam_instance_profile', :value_callback => method(:iam_name_from_profile)}
          ].flatten.compact
          
          @columns_with_info << {:label => 'AZ', :key => 'availability_zone', :value_callback => method(:azcolor)} if config[:az]

          if config[:tags]
            config[:tags].split(",").collect do |tag_name|
              @columns_with_info << {:label => 'Tags:'+tag_name, :key => 'tags', :nested_values => tag_name}
            end
          end  

          super
        end

        def get_instance_name(tags)
          return tags['Name'] if tags['Name']
        end

        def get_security_groups(groups)
          groups.join(", ")
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

        def iam_name_from_profile(profile)
          # The IAM profile object only contains the name as part of the arn
          if profile && profile.key?('arn')
            name = profile['arn'].split('/')[-1]
          end
          name ||= ''
        end 
      end
    end
  end
end
