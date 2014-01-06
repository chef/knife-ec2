#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
require 'chef/knife/cloud/fog/options'

class Chef
  class Knife
    class Cloud
      module Ec2ServiceOptions

       def self.included(includer)
          includer.class_eval do
            include FogOptions
            # Ec2 Connection params.
            option :aws_access_key_id,
              :short => "-A ID",
              :long => "--aws-access-key-id KEY",
              :description => "Your AWS Access Key ID",
              :proc => Proc.new { |key| Chef::Config[:knife][:aws_access_key_id] = key }

            option :aws_secret_access_key,
              :short => "-K SECRET",
              :long => "--aws-secret-access-key SECRET",
              :description => "Your AWS API Secret Access Key",
              :proc => Proc.new { |key| Chef::Config[:knife][:aws_secret_access_key] = key }

            option :aws_credential_file,
              :long => "--aws-credential-file FILE",
              :description => "File containing AWS credentials as used by aws cmdline tools",
              :proc => Proc.new { |key| Chef::Config[:knife][:aws_credential_file] = key }

            option :region,
              :long => "--region REGION",
              :description => "Your AWS region",
              :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }

          end
        end
      end
    end
  end
end