#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/ec2_service_options'
require 'chef/knife/cloud/ec2_service'

class Chef
  class Knife
    class Cloud
      module Ec2Helpers

        def create_service_instance
          Ec2Service.new
        end

        def validate!
          super(:aws_access_key_id, :aws_secret_access_key)
        end
      end
    end
  end
end
