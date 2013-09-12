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

          option :region,
            :long => "--region REGION",
            :description => "Your AWS region",
            :proc => Proc.new { |key| Chef::Config[:knife][:region] = key }

          option :api_endpoint,
            :long => "--api-endpoint ENDPOINT",
            :description => "Your API endpoint. Eg, for Eucalyptus it can be 'http://ecc.eucalyptus.com:8773/services/Eucalyptus'",
            #:default => "http://ecc.eucalyptus.com:8773/services/Eucalyptus",
            :proc => Proc.new { |endpoint| Chef::Config[:knife][:api_endpoint] = endpoint }
        end
      end

      def connection
        @connection ||= begin
          auth_params = { :provider => 'AWS',
                          :aws_access_key_id => Chef::Config[:knife][:aws_access_key_id],
                          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
                          :region => locate_config_value(:region)}
          if Chef::Config[:knife][:api_endpoint] || config[:api_endpoint]
            auth_params[:endpoint] = Chef::Config[:knife][:api_endpoint] || config[:api_endpoint]
          end
          connection = Fog::Compute.new(auth_params)
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
end


