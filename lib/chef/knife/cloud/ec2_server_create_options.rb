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
              :long => "--subnet SUBNET-ID",
              :description => "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
              :proc => Proc.new { |key| Chef::Config[:knife][:subnet_id] = key }

            option :private_ip_address,
              :long => "--private-ip-address IP-ADDRESS",
              :description => "allows to specify the private IP address of the instance in VPC mode",
              :proc => Proc.new { |ip| Chef::Config[:knife][:private_ip_address] = ip }

            option :fqdn,
              :long => "--fqdn FQDN",
              :description => "Pre-defined FQDN",
              :proc => Proc.new { |key| Chef::Config[:knife][:fqdn] = key },
              :default => nil

            option :aws_user_data,
              :long => "--user-data USER_DATA_FILE",
              :short => "-u USER_DATA_FILE",
              :description => "The EC2 User Data file to provision the instance with",
              :proc => Proc.new { |m| Chef::Config[:knife][:aws_user_data] = m },
              :default => nil

            option :ephemeral,
              :long => "--ephemeral EPHEMERAL_DEVICES",
              :description => "Comma separated list of device locations (eg - /dev/sdb) to map ephemeral devices",
              :proc => lambda { |o| o.split(/[\s,]+/) },
              :default => []

            option :server_connect_attribute,
              :long => "--server-connect-attribute ATTRIBUTE",
              :short => "-a ATTRIBUTE",
              :description => "The EC2 server attribute to use for SSH connection. Use this attr for creating VPC instances along with --associate-eip",
              :default => nil

            option :associate_public_ip,
              :long => "--associate-public-ip",
              :description => "Associate public ip to VPC instance.",
              :boolean => true,
              :default => false

            option :ebs_volume_type,
              :long => "--ebs-volume-type TYPE",
              :description => "Standard or Provisioned (io1) IOPS or General Purpose (gp2)",
              :proc => Proc.new { |key| Chef::Config[:knife][:ebs_volume_type] = key },
              :default => "standard"

            option :ebs_provisioned_iops,
              :long => "--provisioned-iops IOPS",
              :description => "IOPS rate, only used when ebs volume type is 'io1'",
              :proc => Proc.new { |key| Chef::Config[:knife][:provisioned_iops] = key },
              :default => nil

            option :s3_secret,
              :long => '--s3-secret S3_SECRET_URL',
              :description => 'S3 URL (e.g. s3://bucket/file) for the ' \
                'encrypted_data_bag_secret_file',
              :proc => lambda { |url| Chef::Config[:knife][:s3_secret] = url }

            option :validation_key_url,
              :long => '--validation-key-url URL',
              :description => 'Path to the validation key',
              :proc => proc { |m| Chef::Config[:validation_key_url] = m }

            option :ebs_encrypted,
              :long => '--ebs-encrypted',
              :description => 'Enables EBS volume encryption',
              :boolean => true,
              :default => false

=begin
            option :distro,
              :short => "-d DISTRO",
              :long => "--distro DISTRO",
              :description => "Bootstrap a distro using a template. [DEPRECATED] Use --bootstrap-template option instead.",
              :proc        => Proc.new { |v|
                Chef::Log.warn("[DEPRECATED] -d / --distro option is deprecated. Use --bootstrap-template option instead.")
                v
              }

            option :template_file,
              :long => "--template-file TEMPLATE",
              :description => "Full path to location of template to use. [DEPRECATED] Use -t / --bootstrap-template option instead.",
              :proc        => Proc.new { |v|
                Chef::Log.warn("[DEPRECATED] --template-file option is deprecated. Use -t / --bootstrap-template option instead.")
                v
              }
=end

            option :bootstrap_template,
              :long => "--bootstrap-template TEMPLATE",
              :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

            option :node_ssl_verify_mode,
              :long        => "--node-ssl-verify-mode [peer|none]",
              :description => "Whether or not to verify the SSL cert for all HTTPS requests.",
              :proc        => Proc.new { |v|
                valid_values = ["none", "peer"]
                unless valid_values.include?(v)
                  raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
                end
              }

            option :node_verify_api_cert,
              :long        => "--[no-]node-verify-api-cert",
              :description => "Verify the SSL cert for HTTPS requests to the Chef server API.",
              :boolean     => true

            option :bootstrap_no_proxy,
              :long => "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
              :description => "Do not proxy locations for the node being bootstrapped; this option is used internally by Opscode",
              :proc => Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

            option :bootstrap_url,
              :long        => "--bootstrap-url URL",
              :description => "URL to a custom installation script",
              :proc        => Proc.new { |u| Chef::Config[:knife][:bootstrap_url] = u }

            option :bootstrap_install_command,
              :long        => "--bootstrap-install-command COMMANDS",
              :description => "Custom command to install chef-client",
              :proc        => Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

            option :bootstrap_wget_options,
              :long        => "--bootstrap-wget-options OPTIONS",
              :description => "Add options to wget when installing chef-client",
              :proc        => Proc.new { |wo| Chef::Config[:knife][:bootstrap_wget_options] = wo }

            option :bootstrap_curl_options,
              :long        => "--bootstrap-curl-options OPTIONS",
              :description => "Add options to curl when install chef-client",
              :proc        => Proc.new { |co| Chef::Config[:knife][:bootstrap_curl_options] = co }

            option :bootstrap_vault_file,
              :long        => '--bootstrap-vault-file VAULT_FILE',
              :description => 'A JSON file with a list of vault(s) and item(s) to be updated'

            option :bootstrap_vault_json,
              :long        => '--bootstrap-vault-json VAULT_JSON',
              :description => 'A JSON string with the vault(s) and item(s) to be updated'

            option :bootstrap_vault_item,
              :long        => '--bootstrap-vault-item VAULT_ITEM',
              :description => 'A single vault and item to update as "vault:item"',
              :proc        => Proc.new { |i|
                (vault, item) = i.split(/:/)
                Chef::Config[:knife][:bootstrap_vault_item] ||= {}
                Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
                Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
                Chef::Config[:knife][:bootstrap_vault_item]
              }

            option :use_sudo_password,
              :long => "--use-sudo-password",
              :description => "Execute the bootstrap via sudo with password",
              :boolean => false

          end
        end
      end
    end
  end
end