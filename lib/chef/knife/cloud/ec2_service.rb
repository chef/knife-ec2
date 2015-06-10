#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/fog/service'

class Chef
  class Knife
    class Cloud
      class Ec2Service < FogService

        def initialize(options = {})
          Chef::Log.debug("aws_access_key_id #{Chef::Config[:knife][:aws_access_key_id]}")
          Chef::Log.debug("aws_secret_access_key #{Chef::Config[:knife][:aws_secret_access_key]}")
          Chef::Log.debug("aws_credential_file #{Chef::Config[:knife][:aws_credential_file]}")
          Chef::Log.debug("region #{Chef::Config[:knife][:region].to_s}")

          super(options.merge({
                              :auth_params => {
                                :provider => 'AWS',
                                :aws_access_key_id => Chef::Config[:knife][:aws_access_key_id],
                                :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
                                :region => Chef::Config[:knife][:region]
                }}))
        end

        # add alternate user defined api_endpoint value.
        def add_api_endpoint
        end

        def get_server_name(server)
          server.tags['Name'] if server.tags['Name']
        end
      end
    end
  end
end
