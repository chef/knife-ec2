require 'chef/knife'

class Chef
  class Knife
    module Ec2VolumeBase

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

          option :volume_count,
            :short => "-c COUNT",
            :long => "--volume-count COUNT",
            :description => "Specify how many volume to create",
            :default => 1

          option :availability_zone,
            :short => "-Z ZONE",
            :long => "--availability-zone ZONE",
            :description => "The Availability Zone",
            :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

          option :volume_size,
            :short => "-S SIZE",
            :long => "--size SIZE",
            :description => "The size of the EBS volume in GB",
            :proc => Proc.new { |size| Chef::Config[:knife][:volume_size] = size }

          option :iops,
            :short => "-io IOPS",
            :long => "--iops IOPS",
            :description => "Provisioned IOPS for the volume"

          option :encrypted,
            :short => "-e BOOLEAN",
            :long => "--encrypted BOOLEAN",
            :description => "BOOLEAN to determine EBS encryption",
            :default => false
        end
      end

      def create_volumes!
        count = config[:volume_count].to_i
        @volumes ||= []
        options = {}
        options['VolumeType'] = 'io1' if config[:iops]
        options['Iops'] = config[:iops] if config[:iops]
        #options['Encrypted'] = config[:encrypted]

        count.times do |i|
          volume = connection.create_volume(availability_zone,volume_size, options)
          msg_pair("Availability Zone", volume.data[:body]["availabilityZone"])
          msg_pair("Volume Size", volume.data[:body]["size"])
          msg_pair("Volume ID", volume.data[:body]["volumeId"])
          @volumes << volume.data[:body]["volumeId"]
        end
        @volumes
      end

      def volume_size
        locate_config_value(:volume_size)
      end

      def availability_zone
        locate_config_value(:availability_zone)
      end

    end
  end
end