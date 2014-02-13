# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

require 'chef/knife/cloud/list_resource_command'
require 'chef/knife/ec2_helpers'
require 'chef/knife/cloud/ec2_service_options'

class Chef
  class Knife
    class Cloud
      class Ec2FlavorList < ResourceListCommand
        include Ec2Helpers
        include Ec2ServiceOptions

        banner "knife ec2 flavor list (options)"

        def before_exec_command
          #set columns_with_info map
          @columns_with_info = [
          {:label => 'ID', :key => 'id'},
          {:label => 'Name', :key => 'name'},
          {:label => 'RAM', :key => 'ram', :value_callback => method(:ram_in_mb)},
          {:label => 'Disk', :key => 'disk', :value_callback => method(:disk_in_gb)},
          {:label => 'Bits', :key => 'bits'},
          {:label => 'Cores', :key => 'cores'}
        ]
        end

        def query_resource
          @service.list_resource_configurations
        end

        def ram_in_mb(ram)
          "#{ram} MB"
        end

        def disk_in_gb(disk)
          "#{disk} GB"
        end
      end
    end
  end
end