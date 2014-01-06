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

        def before_exec_command
          #set columns_with_info map
          @columns_with_info = [
          {:label => 'Instance ID', :key => 'id'},
          {:label => 'Name', :key => 'tags', :value_callback => method(:get_instance_name)},
          {:label => 'Public IP', :key => 'public_ip_address'},
          {:label => 'Private IP', :key => 'private_ip_address'},
          {:label => 'Flavor', :key => 'flavor_id'},
          {:label => 'Image', :key => 'image_id'},
          {:label => 'Keypair', :key => 'key_name'},
          {:label => 'State', :key => 'state'}
        ]
          super
        end

        def get_instance_name(tags)
          return tags['Name'] if tags['Name']
        end  
      end
    end
  end
end
