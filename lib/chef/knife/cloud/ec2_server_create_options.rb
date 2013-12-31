
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

            option :associate_eip,
              :long => "--associate-eip IP_ADDRESS",
              :description => "Associate existing elastic IP address with instance after launch"  

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

            option :iam_instance_profile,
              :long => "--iam-profile NAME",
              :description => "The IAM instance profile to apply to this instance."

            option :security_group_ids,
              :short => "-g X,Y,Z",
              :long => "--security-group-ids X,Y,Z",
              :description => "The security group ids for this server; required when using VPC",
              :proc => Proc.new { |security_group_ids| security_group_ids.split(',') }

            option :dedicated_instance,
              :long => "--dedicated_instance",
              :description => "Launch as a Dedicated instance (VPC ONLY)"
              
            option :placement_group,
              :long => "--placement-group PLACEMENT_GROUP",
              :description => "The placement group to place a cluster compute instance",
              :proc => Proc.new { |pg| Chef::Config[:knife][:placement_group] = pg }

            option :tags,
              :short => "-T T=V[,T=V,...]",
              :long => "--tags Tag=Value[,Tag=Value...]",
              :description => "The tags for this server",
              :proc => Proc.new { |tags| tags.split(',') }

            option :ebs_size,
              :long => "--ebs-size SIZE",
              :description => "The size of the EBS volume in GB, for EBS-backed instances"

            option :ebs_optimized,
              :long => "--ebs-optimized",
              :description => "Enabled optimized EBS I/O"

            option :ebs_no_delete_on_term,
              :long => "--ebs-no-delete-on-term",
              :description => "Do not delete EBS volume on instance termination"

            option :subnet_id,
              :short => "-s SUBNET-ID",
              :long => "--subnet SUBNET-ID",
              :description => "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
              :proc => Proc.new { |key| Chef::Config[:knife][:subnet_id] = key }

            option :fqdn,
              :long => "--fqdn FQDN",
              :description => "Pre-defined FQDN",
              :proc => Proc.new { |key| Chef::Config[:knife][:fqdn] = key },
              :default => nil

            option :ec2_user_data,
              :long => "--user-data USER_DATA_FILE",
              :short => "-u USER_DATA_FILE",
              :description => "The EC2 User Data file to provision the instance with",
              :proc => Proc.new { |m| Chef::Config[:knife][:ec2_user_data] = m },
              :default => nil

            option :ephemeral,
              :long => "--ephemeral EPHEMERAL_DEVICES",
              :description => "Comma separated list of device locations (eg - /dev/sdb) to map ephemeral devices",
              :proc => lambda { |o| o.split(/[\s,]+/) },
              :default => []

            option :server_connect_attribute,
              :long => "--server-connect-attribute ATTRIBUTE",
              :short => "-a ATTRIBUTE",
              :description => "The EC2 server attribute to use for SSH connection",
              :default => nil

          end
        end
      end
    end
  end
end
