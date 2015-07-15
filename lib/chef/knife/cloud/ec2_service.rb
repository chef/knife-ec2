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

          options.merge!({
                              :auth_params => {
                                :provider => 'AWS',
                                :region => Chef::Config[:knife][:region]
                }})

          if Chef::Config[:knife][:use_iam_profile]
            options[:auth_params][:use_iam_profile] = true
          else
            options[:auth_params][:aws_access_key_id] = Chef::Config[:knife][:aws_access_key_id]
            options[:auth_params][:aws_secret_access_key] = Chef::Config[:knife][:aws_secret_access_key]
          end

          super(options)
        end

        # add alternate user defined api_endpoint value.
        def add_api_endpoint
        end

        def get_server_name(server)
          server.tags['Name'] ? server.tags['Name'] : ''
        end
      end
    end
  end
end
