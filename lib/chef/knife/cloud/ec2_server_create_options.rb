
require 'chef/knife/cloud/server/create_options'

class Chef
  class Knife
    class Cloud
      module Ec2ServerCreateOptions

       def self.included(includer)
          includer.class_eval do
            include ServerCreateOptions

            # Ec2 Server create params.

            option :ec2_security_groups,
              :short => "-G X,Y,Z",
              :long => "--ec2-groups X,Y,Z",
              :description => "The security groups for this server; not allowed when using VPC",
              :proc => Proc.new { |groups| groups.split(',') }

            option :availability_zone,
              :short => "-Z ZONE",
              :long => "--availability-zone ZONE",
              :description => "The Availability Zone",
              :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

            option :ec2_ssh_key_id,
              :short => "-S KEY",
              :long => "--ec2-ssh-key-id KEY",
              :description => "The ec2 SSH keypair id",
              :proc => Proc.new { |key| Chef::Config[:knife][:ec2_ssh_key_id] = key }

          end
        end
      end
    end
  end
end
