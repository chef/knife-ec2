#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2015 Chef Software, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    module Ec2Base

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog/aws'
            require 'readline'
            require 'chef/json_compat'
          end

          option :aws_credential_file,
            :long => "--aws-credential-file FILE",
            :description => "File containing AWS credentials as used by AWS command line tools",
            :proc => Proc.new { |key| Chef::Config[:knife][:aws_credential_file] = key }

          option :aws_config_file,
            :long => "--aws-config-file FILE",
            :description => "File containing AWS configurations as used by aws cmdline tools",
            :proc => Proc.new {|key| Chef::Config[:knife][:aws_config_file] = key}

          option :aws_profile,
            :long => "--aws-profile PROFILE",
            :description => "AWS profile, from AWS credential file and AWS config file, to use",
            :default => 'default',
            :proc => Proc.new { |key| Chef::Config[:knife][:aws_profile] = key }

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

          option :aws_session_token,
            :long => "--aws-session-token TOKEN",
            :description => "Your AWS Session Token, for use with AWS STS Federation or Session Tokens",
            :proc => Proc.new { |key| Chef::Config[:knife][:aws_session_token] = key }

          option :region,
            :long => "--region REGION",
            :description => "Your AWS region",
            :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }

          option :use_iam_profile,
            :long => "--use-iam-profile",
            :description => "Use IAM profile assigned to current machine",
            :boolean => true,
            :default => false,
            :proc => Proc.new { |key| Chef::Config[:knife][:use_iam_profile] = key }
        end
      end

      def connection
        connection_settings = {
          :provider => 'AWS',
          :region => locate_config_value(:region)
        }

        if locate_config_value(:use_iam_profile)
          connection_settings[:use_iam_profile] = true
        else
          connection_settings[:aws_access_key_id] = locate_config_value(:aws_access_key_id)
          connection_settings[:aws_secret_access_key] = locate_config_value(:aws_secret_access_key)
          connection_settings[:aws_session_token] = locate_config_value(:aws_session_token)
        end
        @connection ||= begin
          connection = Fog::Compute.new(connection_settings)
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          ui.info("#{ui.color(label, color)}: #{value}")
        end
      end

      def is_image_windows?
        image_info = connection.images.get(@server.image_id)
        return image_info.platform == 'windows'
      end

      def validate!(keys=[:aws_access_key_id, :aws_secret_access_key])
        errors = []

        if locate_config_value(:aws_config_file)
          aws_config = ini_parse(File.read(locate_config_value(:aws_config_file)))
          profile = if locate_config_value(:aws_profile) == 'default'
                      'default'
                    else
                      "profile #{locate_config_value(:aws_profile)}"
                    end

          unless aws_config.values.empty?
            if aws_config[profile]
               Chef::Config[:knife][:region] = aws_config[profile]['region']
            else
              raise ArgumentError, "The provided --aws-profile '#{profile}' is invalid."
            end
          end
        end

        unless locate_config_value(:use_iam_profile)
          if locate_config_value(:aws_credential_file)
            unless (Chef::Config[:knife].keys & [:aws_access_key_id, :aws_secret_access_key]).empty?
              errors << "Either provide a credentials file or the access key and secret keys but not both."
            end
            # File format:
            # AWSAccessKeyId=somethingsomethingdarkside
            # AWSSecretKey=somethingsomethingcomplete
            #               OR
            # [default]
            # aws_access_key_id = somethingsomethingdarkside
            # aws_secret_access_key = somethingsomethingdarkside

            aws_creds = ini_parse(File.read(locate_config_value(:aws_credential_file)))
            profile = locate_config_value(:aws_profile)

            entries = if aws_creds.values.first.has_key?("AWSAccessKeyId")
                        aws_creds.values.first
                      else
                        aws_creds[profile]
                      end

            if entries
              Chef::Config[:knife][:aws_access_key_id] = entries['AWSAccessKeyId'] || entries['aws_access_key_id']
              Chef::Config[:knife][:aws_secret_access_key] = entries['AWSSecretKey'] || entries['aws_secret_access_key']
              Chef::Config[:knife][:aws_session_token] = entries['AWSSessionToken'] || entries['aws_session_token']
            else
              raise ArgumentError, "The provided --aws-profile '#{profile}' is invalid."
            end
          end

          keys.each do |k|
            pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
            if Chef::Config[:knife][k].nil?
              errors << "You did not provide a valid '#{pretty_key}' value."
            end
          end

          if errors.each{|e| ui.error(e)}.any?
            exit 1
          end
        end

        if locate_config_value(:platform)
          unless valid_platforms.include? (locate_config_value(:platform))
            raise ArgumentError, "Invalid platform: #{locate_config_value(:platform)}. Allowed platforms are: #{valid_platforms.join(", ")}."
          end
        end

        if locate_config_value(:owner)
          unless ["self", "aws-marketplace", "microsoft"].include? (locate_config_value(:owner))
            raise ArgumentError, "Invalid owner: #{locate_config_value(:owner)}. Allowed owners are self, aws-marketplace or microsoft."
          end
        end
      end

    end

    def iam_name_from_profile(profile)
      # The IAM profile object only contains the name as part of the arn
      if profile && profile.key?('arn')
        name = profile['arn'].split('/')[-1]
      end
      name ||= ''
    end

    def ini_parse(file)
      current_section = {}
      map = {}
      file.each_line do |line|
        line = line.split(/^|\s;/).first # remove comments
        section = line.match(/^\s*\[([^\[\]]+)\]\s*$/) unless line.nil?
        if section
          current_section = section[1]
        elsif current_section
          item = line.match(/^\s*(.+?)\s*=\s*(.+?)\s*$/) unless line.nil?
          if item
            map[current_section] ||= {}
            map[current_section][item[1]] = item[2]
          end
        end
      end
      map
    end

    # All valid platforms
    def valid_platforms
      ["windows", "ubuntu", "debian", "centos", "fedora", "rhel", "nginx", "turnkey", "jumpbox", "coreos", "cisco", "amazon", "nessus"]
    end

    # Get the platform from server name
    def find_server_platform(server_name)
      get_platform = valid_platforms.select { |name| server_name.downcase.include?(name) }
      return get_platform.first
    end


    # Custom Warning
    def custom_warnings!
      if !config[:region] && Chef::Config[:knife][:region].nil?
        ui.warn "No region was specified in knife.rb or as an argument. The default region, us-east-1, will be used:"
      end
    end
  end
end
