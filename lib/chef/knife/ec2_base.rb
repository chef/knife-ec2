#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :aws_credential_file,
            :long => "--aws-credential-file FILE",
            :description => "File containing AWS credentials as used by aws cmdline tools",
            :proc => Proc.new { |key| Chef::Config[:knife][:aws_credential_file] = key }

          option :aws_profile,
            :long => "--aws-profile PROFILE",
            :description => "AWS profile, from credential file, to use",
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
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def is_image_windows?
        image_info = connection.images.get(@server.image_id)
        return image_info.platform == 'windows'
      end

      def validate!(keys=[:aws_access_key_id, :aws_secret_access_key])
        errors = []

        unless locate_config_value(:use_iam_profile)
          unless Chef::Config[:knife][:aws_credential_file].nil?
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

            aws_creds = ini_parse(File.read(Chef::Config[:knife][:aws_credential_file]))
            profile = Chef::Config[:knife][:aws_profile] || 'default'
            entries = aws_creds.values.first.has_key?("AWSAccessKeyId") ? aws_creds.values.first : aws_creds[profile]

            Chef::Config[:knife][:aws_access_key_id] = entries['AWSAccessKeyId'] || entries['aws_access_key_id']
            Chef::Config[:knife][:aws_secret_access_key] = entries['AWSSecretKey'] || entries['aws_secret_access_key']
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
  end
end
