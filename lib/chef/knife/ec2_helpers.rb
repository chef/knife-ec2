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
          errors = []
          unless Chef::Config[:knife][:aws_credential_file].nil?
            unless (Chef::Config[:knife].keys & [:aws_access_key_id, :aws_secret_access_key]).empty?
              errors << "Either provide a credentials file or the access key and secret keys but not both."
            end
            
            # File format:
            # AWSAccessKeyId=somethingsomethingdarkside
            # AWSSecretKey=somethingsomethingcomplete
            entries = Hash[*File.read(Chef::Config[:knife][:aws_credential_file]).split(/[=\n]/)]
            Chef::Config[:knife][:aws_access_key_id] = entries['AWSAccessKeyId']
            Chef::Config[:knife][:aws_secret_access_key] = entries['AWSSecretKey']
            error_message = ""
            raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?        
          end
          super(:aws_access_key_id, :aws_secret_access_key)
        end

        def iam_name_from_profile(profile)
          # The IAM profile object only contains the name as part of the arn
          name = profile['arn'].split('/')[-1] if profile && profile.key?('arn')
          name ||= ''
        end
      end
    end
  end
end
