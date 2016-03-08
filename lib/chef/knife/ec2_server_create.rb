#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2010-2015 Chef Software, Inc.
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

require 'chef/knife/ec2_base'
require 'chef/knife/s3_source'
require 'chef/knife/winrm_base'
require 'chef/knife/bootstrap_windows_base'

class Chef
  class Knife
    class Ec2ServerCreate < Knife

      include Knife::Ec2Base
      include Knife::WinrmBase
      include Knife::BootstrapWindowsBase
      deps do
        require 'tempfile'
        require 'fog/aws'
        require 'uri'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server create (options)"

      attr_accessor :initial_sleep_delay
      attr_reader :server

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server (m1.small, m1.medium, etc)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f }

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The AMI for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i }

      option :iam_instance_profile,
        :long => "--iam-profile NAME",
        :description => "The IAM instance profile to apply to this instance."

      option :security_groups,
        :short => "-G X,Y,Z",
        :long => "--groups X,Y,Z",
        :description => "The security groups for this server; not allowed when using VPC",
        :proc => Proc.new { |groups| groups.split(',') }

      option :security_group_ids,
        :short => "-g X,Y,Z",
        :long => "--security-group-ids X,Y,Z",
        :description => "The security group ids for this server; required when using VPC",
        :proc => Proc.new { |security_group_ids| security_group_ids.split(',') }

      option :associate_eip,
        :long => "--associate-eip IP_ADDRESS",
        :description => "Associate existing elastic IP address with instance after launch"

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

      option :availability_zone,
        :short => "-Z ZONE",
        :long => "--availability-zone ZONE",
        :description => "The Availability Zone",
        :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node",
        :proc => Proc.new { |key| Chef::Config[:knife][:chef_node_name] = key }

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "The AWS SSH key id",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_key_name] = key }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :ssh_gateway,
        :short => "-w GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway server. Any proxies configured in your ssh config are automatically used by default.",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :ssh_gateway_identity,
        :long => "--ssh-gateway-identity IDENTITY_FILE",
        :description => "The private key for ssh gateway server",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway_identity] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :bootstrap_proxy,
        :long => "--bootstrap-proxy PROXY_URL",
        :description => "The proxy server for the node being bootstrapped",
        :proc => Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

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

      option :bootstrap_template,
        :long => "--bootstrap-template TEMPLATE",
        :description => "Bootstrap Chef using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

      option :ebs_size,
        :long => "--ebs-size SIZE",
        :description => "The size of the EBS volume in GB, for EBS-backed instances"

      option :ebs_optimized,
        :long => "--ebs-optimized",
        :description => "Enabled optimized EBS I/O"

      option :ebs_no_delete_on_term,
        :long => "--ebs-no-delete-on-term",
        :description => "Do not delete EBS volume on instance termination"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :secret,
        :long => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :s3_secret,
        :long => '--s3-secret S3_SECRET_URL',
        :description => 'S3 URL (e.g. s3://bucket/file) for the encrypted_data_bag_secret_file',
        :proc => lambda { |url| Chef::Config[:knife][:s3_secret] = url }

      option :subnet_id,
        :long => "--subnet SUBNET-ID",
        :description => "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
        :proc => Proc.new { |key| Chef::Config[:knife][:subnet_id] = key }

      option :private_ip_address,
        :long => "--private-ip-address IP-ADDRESS",
        :description => "allows to specify the private IP address of the instance in VPC mode",
        :proc => Proc.new { |ip| Chef::Config[:knife][:private_ip_address] = ip }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :bootstrap_protocol,
        :long => "--bootstrap-protocol protocol",
        :description => "protocol to bootstrap windows servers. options: winrm/ssh",
        :proc => Proc.new { |key| Chef::Config[:knife][:bootstrap_protocol] = key },
        :default => nil

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

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           Chef::Config[:knife][:hints] ||= {}
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      option :ephemeral,
        :long => "--ephemeral EPHEMERAL_DEVICES",
        :description => "Comma separated list of device locations (eg - /dev/sdb) to map ephemeral devices",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :server_connect_attribute,
        :long => "--server-connect-attribute ATTRIBUTE",
        :short => "-a ATTRIBUTE",
        :description => "The EC2 server attribute to use for the SSH connection if necessary, e.g. public_ip_address or private_ip_address.",
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

      option :auth_timeout,
        :long => "--windows-auth-timeout MINUTES",
        :description => "The maximum time in minutes to wait to for authentication over the transport to the node to succeed. The default value is 25 minutes.",
        :default => 25

      option :validation_key_url,
        :long => "--validation-key-url URL",
        :description => "Path to the validation key",
        :proc => proc { |m| Chef::Config[:validation_key_url] = m }

      option :ebs_encrypted,
        :long => "--ebs-encrypted",
        :description => "Enables EBS volume encryption",
        :boolean => true,
        :default => false

      option :spot_price,
        :long => "--spot-price PRICE",
        :description => "The maximum hourly USD price for the instance",
        :default => nil

      option :spot_request_type,
        :long => "--spot-request-type TYPE",
        :description => "The Spot Instance request type. Possible values are 'one-time' and 'persistent', default value is 'one-time'",
        :default => "one-time"

      option :spot_wait_mode,
        :long => "--spot-wait-mode MODE",
        :description =>
          "Whether we should wait for spot request fulfillment. Could be 'wait', 'exit', or " \
          "'prompt' (default). For any of the above mentioned choices, ('wait') - if the " \
          "instance does not get allocated before the command itself times-out or ('exit') the " \
          "user needs to manually bootstrap the instance in the future after it gets allocated.",
        :default => "prompt"

      option :aws_connection_timeout,
        :long => "--aws-connection-timeout MINUTES",
        :description => "The maximum time in minutes to wait to for aws connection. Default is 10 min",
        :proc => proc {|t| t = t.to_i * 60; Chef::Config[:aws_connection_timeout] = t},
        :default => 600

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

      option :forward_agent,
        :short => "-A",
        :long => "--forward-agent",
        :description => "Enable SSH agent forwarding",
        :boolean => true

      option :create_ssl_listener,
        :long => "--[no-]create-ssl-listener",
        :description => "Create ssl listener, enabled by default.",
        :boolean => true,
        :default => true

      option :network_interfaces,
        :short => '-n',
        :long => '--attach-network-interface ENI1,ENI2',
        :description => 'Attach additional network interfaces during bootstrap',
        :proc => proc { |nics| nics.split(',') }

      option :classic_link_vpc_id,
        :long => "--classic-link-vpc-id VPC_ID",
        :description => "Enable ClassicLink connection with a VPC"

      option :classic_link_vpc_security_group_ids,
        :long => "--classic-link-vpc-security-groups-ids X,Y,Z",
        :description => "Comma-separated list of security group ids for ClassicLink",
        :proc => Proc.new { |groups| groups.split(',') }

      def run
        $stdout.sync = true

        validate!

        requested_elastic_ip = config[:associate_eip] if config[:associate_eip]

        # For VPC EIP assignment we need the allocation ID so fetch full EIP details
        elastic_ip = connection.addresses.detect{|addr| addr if addr.public_ip == requested_elastic_ip}

        if locate_config_value(:spot_price)
          server_def = create_server_def
          server_def[:groups] = config[:security_group_ids] if vpc_mode?
          spot_request = connection.spot_requests.create(server_def)
          msg_pair("Spot Request ID", spot_request.id)
          msg_pair("Spot Request Type", spot_request.request_type)
          msg_pair("Spot Price", spot_request.price)

          case config[:spot_wait_mode]
          when 'prompt', '', nil
            wait_msg = "Do you want to wait for Spot Instance Request fulfillment? (Y/N) \n"
            wait_msg += "Y - Wait for Spot Instance request fulfillment\n"
            wait_msg += "N - Do not wait for Spot Instance request fulfillment. "
            wait_msg += ui.color("[WARN :: Request would be alive on AWS ec2 side but execution of Chef Bootstrap on the target instance will get skipped.]\n", :red, :bold)
            wait_msg += ui.color("\n[WARN :: For any of the above mentioned choices, (Y) - if the instance does not get allocated before the command itself times-out or (N) - user decides to exit, then in both cases user needs to manually bootstrap the instance in the future after it gets allocated.]\n\n", :cyan, :bold)
            confirm(wait_msg)
          when 'wait'
            # wait for the node and run Chef bootstrap
          when 'exit'
            ui.color("The 'exit' option was specified for --spot-wait-mode, exiting.", :cyan)
            exit
          else
            raise "Invalid value for --spot-wait-mode: '#{config[:spot_wait_mode]}', " \
              "valid values: wait, exit, prompt"
          end

          print ui.color("Waiting for Spot Request fulfillment:  ", :cyan)
          spot_request.wait_for do
            @spinner ||= %w{| / - \\}
            print "\b" + @spinner.rotate!.first
            ready?
          end
          puts("\n")
          @server = connection.servers.get(spot_request.instance_id)
        else
          @server = connection.servers.create(create_server_def)
        end

        hashed_tags={}
        tags.map{ |t| key,val=t.split('='); hashed_tags[key]=val} unless tags.nil?

        # Always set the Name tag
        unless hashed_tags.keys.include? "Name"
          hashed_tags["Name"] = locate_config_value(:chef_node_name) || @server.id
        end

        printed_tags = hashed_tags.map{ |tag, val| "#{tag}: #{val}" }.join(", ")

        msg_pair("Instance ID", @server.id)
        msg_pair("Flavor", @server.flavor_id)
        msg_pair("Image", @server.image_id)
        msg_pair("Region", connection.instance_variable_get(:@region))
        msg_pair("Availability Zone", @server.availability_zone)

        # If we don't specify a security group or security group id, Fog will
        # pick the appropriate default one. In case of a VPC we don't know the
        # default security group id at this point unless we look it up, hence
        # 'default' is printed if no id was specified.
        printed_security_groups = "default"
        printed_security_groups = @server.groups.join(", ") if @server.groups
        msg_pair("Security Groups", printed_security_groups) unless vpc_mode? or (@server.groups.nil? and @server.security_group_ids)

        printed_security_group_ids = "default"
        printed_security_group_ids = @server.security_group_ids.join(", ") if @server.security_group_ids
        msg_pair("Security Group Ids", printed_security_group_ids) if vpc_mode? or @server.security_group_ids

        msg_pair("IAM Profile", locate_config_value(:iam_instance_profile))

        msg_pair("Tags", printed_tags)
        msg_pair("SSH Key", @server.key_name)

        print "\n#{ui.color("Waiting for EC2 to create the instance", :magenta)}"

        # wait for instance to come up before acting against it
        @server.wait_for(locate_config_value(:aws_connection_timeout)) { print "."; ready? }

        puts("\n")

        # occasionally 'ready?' isn't, so retry a couple times if needed.
        tries = 6
        begin
          create_tags(hashed_tags) unless hashed_tags.empty?
          associate_eip(elastic_ip) if config[:associate_eip]
          enable_classic_link(config[:classic_link_vpc_id], config[:classic_link_vpc_security_group_ids]) if config[:classic_link_vpc_id]
        rescue Fog::Compute::AWS::NotFound, Fog::Errors::Error
          raise if (tries -= 1) <= 0
          ui.warn("server not ready, retrying tag application (retries left: #{tries})")
          sleep 5
          retry
        end

        attach_nics if config[:network_interfaces]

        if vpc_mode?
          msg_pair("Subnet ID", @server.subnet_id)
          msg_pair("Tenancy", @server.tenancy)
          if config[:associate_public_ip]
            msg_pair("Public DNS Name", @server.dns_name)
          end
          if elastic_ip
            msg_pair("Public IP Address", @server.public_ip_address)
          end
        else
          msg_pair("Public DNS Name", @server.dns_name)
          msg_pair("Public IP Address", @server.public_ip_address)
          msg_pair("Private DNS Name", @server.private_dns_name)
        end
        msg_pair("Private IP Address", @server.private_ip_address)

        if Chef::Config[:knife][:validation_key_url]
          download_validation_key(validation_key_path)
          Chef::Config[:validation_key] = validation_key_path
        end

        #Check if Server is Windows or Linux
        if is_image_windows?
          protocol = locate_config_value(:bootstrap_protocol)
          protocol ||= 'winrm'
          if protocol == 'winrm'
            load_winrm_deps
            print "\n#{ui.color("Waiting for winrm access to become available", :magenta)}"
            print(".") until tcp_test_winrm(ssh_connect_host, locate_config_value(:winrm_port)) {
              sleep 10
              puts("done")
            }
          else
            print "\n#{ui.color("Waiting for sshd access to become available", :magenta)}"
            #If FreeSSHd, winsshd etc are available
            print(".") until tcp_test_ssh(ssh_connect_host, config[:ssh_port]) {
              sleep @initial_sleep_delay ||= (vpc_mode? ? 40 : 10)
              puts("done")
            }
            ssh_override_winrm
          end
          bootstrap_for_windows_node(@server, ssh_connect_host).run
        else
          print "\n#{ui.color("Waiting for sshd access to become available", :magenta)}"
          wait_for_sshd(ssh_connect_host)
          ssh_override_winrm
          bootstrap_for_linux_node(@server, ssh_connect_host).run
        end

        puts "\n"
        msg_pair("Instance ID", @server.id)
        msg_pair("Flavor", @server.flavor_id)
        msg_pair("Placement Group", @server.placement_group) unless @server.placement_group.nil?
        msg_pair("Image", @server.image_id)
        msg_pair("Region", connection.instance_variable_get(:@region))
        msg_pair("Availability Zone", @server.availability_zone)
        msg_pair("Security Groups", printed_security_groups) unless vpc_mode? or (@server.groups.nil? and @server.security_group_ids)
        msg_pair("Security Group Ids", printed_security_group_ids) if vpc_mode? or @server.security_group_ids
        msg_pair("IAM Profile", locate_config_value(:iam_instance_profile)) if locate_config_value(:iam_instance_profile)
        msg_pair("Tags", printed_tags)
        msg_pair("SSH Key", @server.key_name)
        msg_pair("Root Device Type", @server.root_device_type)
        if @server.root_device_type == "ebs"
          device_map = @server.block_device_mapping.first
          msg_pair("Root Volume ID", device_map['volumeId'])
          msg_pair("Root Device Name", device_map['deviceName'])
          msg_pair("Root Device Delete on Terminate", device_map['deleteOnTermination'])
          msg_pair("Standard or Provisioned IOPS", device_map['volumeType'])
          msg_pair("IOPS rate", device_map['iops'])

          print "\n#{ui.color("Block devices", :magenta)}\n"
          print "#{ui.color("===========================", :magenta)}\n"
          @server.block_device_mapping.each do |device_map|
            msg_pair("Device Name", device_map['deviceName'])
            msg_pair("Volume ID", device_map['volumeId'])
            msg_pair("Delete on Terminate", device_map['deleteOnTermination'].to_s)
            msg_pair("Standard or Provisioned IOPS", device_map['volumeType'])
            msg_pair("IOPS rate", device_map['iops'])
            print "\n"
          end
          print "#{ui.color("===========================", :magenta)}\n"

          if config[:ebs_size]
            if ami.block_device_mapping.first['volumeSize'].to_i < config[:ebs_size].to_i
              volume_too_large_warning = "#{config[:ebs_size]}GB " +
                          "EBS volume size is larger than size set in AMI of " +
                          "#{ami.block_device_mapping.first['volumeSize']}GB.\n" +
                          "Use file system tools to make use of the increased volume size."
              msg_pair("Warning", volume_too_large_warning, :yellow)
            end
          end
        end
        if config[:ebs_optimized]
          msg_pair("EBS is Optimized", @server.ebs_optimized.to_s)
        end
        if vpc_mode?
          msg_pair("Subnet ID", @server.subnet_id)
          msg_pair("Tenancy", @server.tenancy)
          if config[:associate_public_ip]
            msg_pair("Public DNS Name", @server.dns_name)
          end
        else
          msg_pair("Public DNS Name", @server.dns_name)
          msg_pair("Public IP Address", @server.public_ip_address)
          msg_pair("Private DNS Name", @server.private_dns_name)
        end
        msg_pair("Private IP Address", @server.private_ip_address)
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", (config[:run_list] || []).join(', '))
        if config[:first_boot_attributes] || config[:first_boot_attributes_from_file]
          msg_pair("JSON Attributes",config[:first_boot_attributes] || config[:first_boot_attributes_from_file])
        end
      end

      def default_bootstrap_template
        is_image_windows? ? 'windows-chef-client-msi' : 'chef-full'
      end

      def validation_key_path
        @validation_key_path ||= begin
          if URI(Chef::Config[:knife][:validation_key_url]).scheme == 'file'
            URI(Chef::Config[:knife][:validation_key_url]).path
          else
            validation_key_tmpfile.path
          end
        end
      end

      def validation_key_tmpfile
        @validation_key_tmpfile ||= Tempfile.new('validation_key')
      end

      def download_validation_key(tempfile)
        Chef::Log.debug 'Downloading validation key ' \
          "<#{Chef::Config[:knife][:validation_key_url]}> to file " \
          "<#{tempfile}>"

        case URI(Chef::Config[:knife][:validation_key_url]).scheme
        when 's3'
          File.open(tempfile, 'w') { |f| f.write(s3_validation_key) }
        end
      end

      def s3_validation_key
        @s3_validation_key ||= begin
          Chef::Knife::S3Source.fetch(Chef::Config[:knife][:validation_key_url])
        end
      end

      def s3_secret
        @s3_secret ||= begin
          return false unless locate_config_value(:s3_secret)
          Chef::Knife::S3Source.fetch(locate_config_value(:s3_secret))
        end
      end

      def bootstrap_common_params(bootstrap)
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro) || default_bootstrap_template
        # setting bootstrap_template value to template_file for backward compatibility
        bootstrap.config[:template_file] = locate_config_value(:template_file) || locate_config_value(:bootstrap_template)
        bootstrap.config[:environment] = locate_config_value(:environment)
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:first_boot_attributes] = locate_config_value(:first_boot_attributes)
        bootstrap.config[:first_boot_attributes_from_file] = locate_config_value(:first_boot_attributes_from_file)
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:secret_file)
        bootstrap.config[:secret] = s3_secret || locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)
        bootstrap.config[:node_ssl_verify_mode] = locate_config_value(:node_ssl_verify_mode)
        bootstrap.config[:node_verify_api_cert] = locate_config_value(:node_verify_api_cert)
        bootstrap.config[:bootstrap_no_proxy] = locate_config_value(:bootstrap_no_proxy)
        bootstrap.config[:bootstrap_url] = locate_config_value(:bootstrap_url)
        bootstrap.config[:bootstrap_install_command] = locate_config_value(:bootstrap_install_command)
        bootstrap.config[:bootstrap_wget_options] = locate_config_value(:bootstrap_wget_options)
        bootstrap.config[:bootstrap_curl_options] = locate_config_value(:bootstrap_curl_options)
        bootstrap.config[:bootstrap_vault_file] = locate_config_value(:bootstrap_vault_file)
        bootstrap.config[:bootstrap_vault_json] = locate_config_value(:bootstrap_vault_json)
        bootstrap.config[:bootstrap_vault_item] = locate_config_value(:bootstrap_vault_item)
        bootstrap.config[:use_sudo_password] = locate_config_value(:use_sudo_password)
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["ec2"] ||= {}
        bootstrap
      end

      def fetch_server_fqdn(ip_addr)
        require 'resolv'
        Resolv.getname(ip_addr)
      end

      def bootstrap_for_windows_node(server, fqdn)
        if locate_config_value(:bootstrap_protocol) == 'winrm' || locate_config_value(:bootstrap_protocol) == nil
          if locate_config_value(:kerberos_realm)
            #Fetch AD/WINS based fqdn if any for Kerberos-based Auth
            fqdn = locate_config_value(:fqdn) || fetch_server_fqdn(server.private_ip_address)
          end
          bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
          bootstrap.config[:winrm_user] = locate_config_value(:winrm_user)
          bootstrap.config[:winrm_password] = windows_password
          bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)
          bootstrap.config[:kerberos_keytab_file] = locate_config_value(:kerberos_keytab_file)
          bootstrap.config[:kerberos_realm] = locate_config_value(:kerberos_realm)
          bootstrap.config[:kerberos_service] = locate_config_value(:kerberos_service)
          bootstrap.config[:ca_trust_file] = locate_config_value(:ca_trust_file)
          bootstrap.config[:winrm_port] = locate_config_value(:winrm_port)
          bootstrap.config[:auth_timeout] = locate_config_value(:auth_timeout)
          bootstrap.config[:winrm_ssl_verify_mode] = locate_config_value(:winrm_ssl_verify_mode)
        elsif locate_config_value(:bootstrap_protocol) == 'ssh'
          bootstrap = Chef::Knife::BootstrapWindowsSsh.new
          bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
          bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
          bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
          bootstrap.config[:identity_file] = locate_config_value(:identity_file)
          bootstrap.config[:no_host_key_verify] = locate_config_value(:no_host_key_verify)
          bootstrap.config[:forward_agent] = locate_config_value(:forward_agent)
        else
          ui.error("Unsupported Bootstrapping Protocol. Supported : winrm, ssh")
          exit 1
        end
        bootstrap.name_args = [fqdn]
        bootstrap.config[:msi_url] = locate_config_value(:msi_url)
        bootstrap.config[:install_as_service] = locate_config_value(:install_as_service)
        bootstrap.config[:session_timeout] = locate_config_value(:session_timeout)
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap_common_params(bootstrap)
      end

      def bootstrap_for_linux_node(server,ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.id
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap_common_params(bootstrap)
      end

      def vpc_mode?
        # Amazon Virtual Private Cloud requires a subnet_id. If
        # present, do a few things differently
        !!locate_config_value(:subnet_id)
      end

      def ami
        @ami ||= connection.images.get(locate_config_value(:image))
      end

      def validate!
        if Chef::Config[:knife].keys.include? :aws_ssh_key_id
          Chef::Config[:knife][:ssh_key_name] = Chef::Config[:knife][:aws_ssh_key_id] if !Chef::Config[:knife][:ssh_key_name]
          Chef::Config[:knife].delete(:aws_ssh_key_id)
          ui.warn("Use of aws_ssh_key_id option in knife.rb config is deprecated, use ssh_key_name option instead.")
        end

        super([:image, :ssh_key_name, :aws_access_key_id, :aws_secret_access_key])

        validate_nics! if locate_config_value(:network_interfaces)

        if ami.nil?
          ui.error("You have not provided a valid image (AMI) value.")
          exit 1
        end

        if vpc_mode? and !!config[:security_groups]
          ui.error("You are using a VPC, security groups specified with '-G' are not allowed, specify one or more security group ids with '-g' instead.")
          exit 1
        end

        if !vpc_mode? and !!config[:private_ip_address]
          ui.error("You can only specify a private IP address if you are using VPC.")
          exit 1
        end

        if config[:dedicated_instance] and !vpc_mode?
          ui.error("You can only specify a Dedicated Instance if you are using VPC.")
          exit 1
        end

        if !vpc_mode? and config[:associate_public_ip]
          ui.error("--associate-public-ip option only applies to VPC instances, and you have not specified a subnet id.")
          exit 1
        end

        if config[:associate_eip]
          eips = connection.addresses.collect{|addr| addr if addr.domain == eip_scope}.compact

          unless eips.detect{|addr| addr.public_ip == config[:associate_eip] && addr.server_id == nil}
            ui.error("Elastic IP requested is not available.")
            exit 1
          end
        end

        if config[:ebs_provisioned_iops] and config[:ebs_volume_type] != 'io1'
          ui.error("--provisioned-iops option is only supported for volume type of 'io1'")
          exit 1
        end

        if config[:ebs_volume_type] == 'io1' and config[:ebs_provisioned_iops].nil?
          ui.error("--provisioned-iops option is required when using volume type of 'io1'")
          exit 1
        end

        if config[:ebs_volume_type] and ! %w(gp2 io1 standard).include?(config[:ebs_volume_type])
          ui.error("--ebs-volume-type must be 'standard' or 'io1' or 'gp2'")
          msg opt_parser
          exit 1
        end

        if config[:security_groups] && config[:security_groups].class == String
          ui.error("Invalid value type for knife[:security_groups] in knife configuration file (i.e knife.rb). Type should be array. e.g - knife[:security_groups] = ['sgroup1']")
          exit 1
        end

        if config[:security_group_ids] && config[:security_group_ids].class == String
          ui.error("Invalid value type for knife[:security_group_ids] in knife configuration file (i.e knife.rb). Type should be array. e.g - knife[:security_group_ids] = ['sgroup1']")
          exit 1
        end

        if config[:classic_link_vpc_id].nil? ^ config[:classic_link_vpc_security_group_ids].nil?
          ui.error("--classic-link-vpc-id and --classic-link-vpc-security-group-ids must be used together")
          exit 1
        end

        if vpc_mode? and config[:classic_link_vpc_id]
          ui.error("You can only use ClassicLink if you are not using a VPC")
          exit 1
        end

        if locate_config_value(:ebs_encrypted)
          error_message = ""
          errors = []
          # validation for flavor and ebs_encrypted
          if !locate_config_value(:flavor)
            ui.error("--ebs-encrypted option requires valid flavor to be specified.")
            exit 1
          elsif (locate_config_value(:ebs_encrypted) and ! %w(m3.medium  m3.large  m3.xlarge m3.2xlarge m4.large m4.xlarge
                                             m4.2xlarge m4.4xlarge m4.10xlarge t2.micro t2.small t2.medium t2.large
                                             d2.xlarge  d2.2xlarge d2.4xlarge d2.8xlarge c4.large c4.xlarge
                                             c4.2xlarge c4.4xlarge c4.8xlarge c3.large c3.xlarge c3.2xlarge
                                             c3.4xlarge c3.8xlarge cr1.8xlarge r3.large r3.xlarge r3.2xlarge
                                             r3.4xlarge r3.8xlarge i2.xlarge i2.2xlarge i2.4xlarge i2.8xlarge g2.2xlarge g2.8xlarge).include?(locate_config_value(:flavor)))
            ui.error("--ebs-encrypted option is not supported for #{locate_config_value(:flavor)} flavor.")
            exit 1
          end

          # validation for ebs_size and ebs_volume_type and ebs_encrypted
          if !locate_config_value(:ebs_size)
            errors << "--ebs-encrypted option requires valid --ebs-size to be specified."
          elsif locate_config_value(:ebs_volume_type) == "gp2" and ! locate_config_value(:ebs_size).to_i.between?(1, 16384)
            errors << "--ebs-size should be in between 1-16384 for 'gp2' ebs volume type."
          elsif locate_config_value(:ebs_volume_type) == "io1" and ! locate_config_value(:ebs_size).to_i.between?(4, 16384)
            errors << "--ebs-size should be in between 4-16384 for 'io1' ebs volume type."
          elsif locate_config_value(:ebs_volume_type) == "standard" and ! locate_config_value(:ebs_size).to_i.between?(1, 1024)
            errors << "--ebs-size should be in between 1-1024 for 'standard' ebs volume type."
          end

          if errors.each{|e| error_message = "#{error_message} #{e}"}.any?
            ui.error(error_message)
            exit 1
          end
        end

      end

      def tags
       tags = locate_config_value(:tags)
        if !tags.nil? and tags.length != tags.to_s.count('=')
          ui.error("Tags should be entered in a key = value pair")
          exit 1
        end
       tags
      end

      def eip_scope
        if vpc_mode?
          "vpc"
        else
          "standard"
        end
      end

      def ssl_config_user_data
<<-EOH

If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
  winrm quickconfig -q
}
If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
  winrm delete winrm/config/listener?Address=*+Transport=HTTP
}
$vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
New-SelfSignedCertificate -certstorelocation cert:\\localmachine\\my -dnsname $vm_name
$thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
$create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
iex $create_listener_cmd

netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=public enable=yes

EOH
      end

      def ssl_config_data_already_exist?
        File.read(locate_config_value(:aws_user_data)).gsub(/\\\\/,"\\").include? ssl_config_user_data.strip
      end

      def process_user_data(script_lines)
        if !ssl_config_data_already_exist?
          ps_start_tag = "<powershell>\n"
          ps_end_tag = "</powershell>\n"
          ps_start_tag_index = script_lines.index(ps_start_tag) || script_lines.index(ps_start_tag.strip)
          ps_end_tag_index = script_lines.index(ps_end_tag) || script_lines.index(ps_end_tag.strip)
          case
          when ( ps_start_tag_index && !ps_end_tag_index ) || ( !ps_start_tag_index && ps_end_tag_index )
            ui.error("Provided user_data file is invalid.")
            exit 1
          when ps_start_tag_index && ps_end_tag_index
            script_lines[ps_end_tag_index] = ssl_config_user_data + ps_end_tag
          when !ps_start_tag_index && !ps_end_tag_index
            script_lines.insert(-1,"\n\n" + ps_start_tag + ssl_config_user_data + ps_end_tag)
          end
        end
        script_lines
      end

      def create_server_def
        server_def = {
          :image_id => locate_config_value(:image),
          :groups => config[:security_groups],
          :security_group_ids => locate_config_value(:security_group_ids),
          :flavor_id => locate_config_value(:flavor),
          :key_name => locate_config_value(:ssh_key_name),
          :availability_zone => locate_config_value(:availability_zone),
          :price => locate_config_value(:spot_price),
          :request_type => locate_config_value(:spot_request_type)
        }
        server_def[:subnet_id] = locate_config_value(:subnet_id) if vpc_mode?
        server_def[:private_ip_address] = locate_config_value(:private_ip_address) if vpc_mode?
        server_def[:placement_group] = locate_config_value(:placement_group)
        server_def[:iam_instance_profile_name] = locate_config_value(:iam_instance_profile)
        server_def[:tenancy] = "dedicated" if vpc_mode? and locate_config_value(:dedicated_instance)
        server_def[:associate_public_ip] = locate_config_value(:associate_public_ip) if vpc_mode? and config[:associate_public_ip]

        if locate_config_value(:winrm_transport) == 'ssl'
          if locate_config_value(:aws_user_data)
            begin
              user_data = File.readlines(locate_config_value(:aws_user_data))
              if config[:create_ssl_listener]
                user_data = process_user_data(user_data)
              end
              user_data = user_data.join
              server_def.merge!(:user_data => user_data)
            rescue
              ui.warn("Cannot read #{locate_config_value(:aws_user_data)}: #{$!.inspect}. Ignoring option.")
            end
          else
            if config[:create_ssl_listener]
              server_def.merge!(:user_data => "<powershell>\n" + ssl_config_user_data + "</powershell>\n")
            end
          end
        else
          if locate_config_value(:aws_user_data)
            begin
              server_def.merge!(:user_data => File.read(locate_config_value(:aws_user_data)))
            rescue
              ui.warn("Cannot read #{locate_config_value(:aws_user_data)}: #{$!.inspect}. Ignoring option.")
            end
          end
        end

        if config[:ebs_optimized]
          server_def[:ebs_optimized] = "true"
        else
          server_def[:ebs_optimized] = "false"
        end

        if ami.root_device_type == "ebs"
          if locate_config_value(:ebs_encrypted)
            ami_map = ami.block_device_mapping[1]
          else
            ami_map = ami.block_device_mapping.first
          end

          ebs_size = begin
                       if config[:ebs_size]
                         Integer(config[:ebs_size]).to_s
                       else
                         ami_map["volumeSize"].to_s
                       end
                     rescue ArgumentError
                       puts "--ebs-size must be an integer"
                       msg opt_parser
                       exit 1
                     end
          delete_term = if config[:ebs_no_delete_on_term]
                          "false"
                        else
                          ami_map["deleteOnTermination"]
                        end
          iops_rate = begin
                        if config[:ebs_provisioned_iops]
                          Integer(config[:ebs_provisioned_iops]).to_s
                        else
                          ami_map["iops"].to_s
                        end
                      rescue ArgumentError
                        puts "--provisioned-iops must be an integer"
                        msg opt_parser
                        exit 1
                      end

          server_def[:block_device_mapping] =
            [{
               'DeviceName' => ami_map["deviceName"],
               'Ebs.VolumeSize' => ebs_size,
               'Ebs.DeleteOnTermination' => delete_term,
               'Ebs.VolumeType' => config[:ebs_volume_type],
             }]
          server_def[:block_device_mapping].first['Ebs.Iops'] = iops_rate unless iops_rate.empty?
          server_def[:block_device_mapping].first['Ebs.Encrypted'] = true if locate_config_value(:ebs_encrypted)
        end

        (config[:ephemeral] || []).each_with_index do |device_name, i|
          server_def[:block_device_mapping] = (server_def[:block_device_mapping] || []) << {'VirtualName' => "ephemeral#{i}", 'DeviceName' => device_name}
        end

        server_def
      end

      def wait_for_sshd(hostname)
        ssh_gateway = get_ssh_gateway_for(hostname)
        ssh_gateway ? wait_for_tunnelled_sshd(ssh_gateway, hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def get_ssh_gateway_for(hostname)
        if config[:ssh_gateway]
          # The ssh_gateway specified in the knife config (if any) takes
          # precedence over anything in the SSH configuration
          Chef::Log.debug("Using ssh gateway #{config[:ssh_gateway]} from knife config")
          config[:ssh_gateway]
        else
          # Next, check if the SSH configuration has a ProxyCommand
          # directive for this host. If there is one, parse out the
          # host from the proxy command
          ssh_proxy = Net::SSH::Config.for(hostname)[:proxy]
          if ssh_proxy.respond_to?(:command_line_template)
            # ssh gateway_hostname nc %h %p
            proxy_pattern = /ssh\s+(\S+)\s+nc/
            matchdata = proxy_pattern.match(ssh_proxy.command_line_template)
            if matchdata.nil?
              Chef::Log.debug("Unable to determine ssh gateway for '#{hostname}' from ssh config template: #{ssh_proxy.command_line_template}")
              nil
            else
              # Return hostname extracted from command line template
              Chef::Log.debug("Using ssh gateway #{matchdata[1]} from ssh config")
              matchdata[1]
            end
          else
            # Return nil if we cannot find an ssh_gateway
            Chef::Log.debug("No ssh gateway found, making a direct connection")
            nil
          end
        end
      end

      def wait_for_tunnelled_sshd(ssh_gateway, hostname)
        initial = true
        print(".") until tunnel_test_ssh(ssh_gateway, hostname) {
          if initial
            initial = false
            sleep (vpc_mode? ? 40 : 10)
          else
            sleep 10
          end
          puts("done")
        }
      end

      def tunnel_test_ssh(ssh_gateway, hostname, &block)
        status = false
        gateway = configure_ssh_gateway(ssh_gateway)
        gateway.open(hostname, config[:ssh_port]) do |local_tunnel_port|
          status = tcp_test_ssh('localhost', local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def configure_ssh_gateway(ssh_gateway)
        gw_host, gw_user = ssh_gateway.split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gateway_options = { :port => gw_port || 22 }

        # Load the SSH config for the SSH gateway host.
        # Set the gateway user if it was not part of the
        # SSH gateway string, and use any configured
        # SSH keys.
        ssh_gateway_config = Net::SSH::Config.for(gw_host)
        gw_user ||= ssh_gateway_config[:user]

        # Always use the gateway keys from the SSH Config
        gateway_keys = ssh_gateway_config[:keys]

        # Use the keys specificed on the command line if available (overrides SSH Config)
        if config[:ssh_gateway_identity]
          gateway_keys = Array(locate_config_value(:ssh_gateway_identity))
        end

        unless gateway_keys.nil?
          gateway_options[:keys] = gateway_keys
        end

        Net::SSH::Gateway.new(gw_host, gw_user, gateway_options)
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        initial = true
        print(".") until tcp_test_ssh(hostname, ssh_port) {
          if initial
            initial = false
            sleep (vpc_mode? ? 40 : 10)
          else
            sleep 10
          end
          puts("done")
        }
      end

      def ssh_connect_host
        unless @ssh_connect_host
          if config[:server_connect_attribute]
            connect_attribute = config[:server_connect_attribute]
          else
            if vpc_mode? && !(config[:associate_public_ip] || config[:associate_eip])
              connect_attribute = "private_ip_address"
            else
              connect_attribute = server.dns_name ? "dns_name" : "public_ip_address"
            end
          end

          @ssh_connect_host = server.send(connect_attribute)
        end

        puts "\nSSH Target Address: #{@ssh_connect_host}(#{connect_attribute})"
        @ssh_connect_host
      end

      def create_tags(hashed_tags)
        hashed_tags.each_pair do |key,val|
          connection.tags.create :key => key, :value => val, :resource_id => @server.id
        end
      end

      def associate_eip(elastic_ip)
        connection.associate_address(server.id, elastic_ip.public_ip, nil, elastic_ip.allocation_id)
        @server.wait_for(locate_config_value(:aws_connection_timeout)) { public_ip_address == elastic_ip.public_ip }
      end

      def validate_nics!
        valid_nic_ids = connection.network_interfaces.all(
          vpc_mode? ? { 'vpc-id' => vpc_id } : {}
        ).map(&:network_interface_id)
        invalid_nic_ids =
          locate_config_value(:network_interfaces) - valid_nic_ids
        return true if invalid_nic_ids.empty?
        ui.error 'The following network interfaces are invalid: ' \
          "#{invalid_nic_ids.join(', ')}"
        exit 1
      end

      def vpc_id
        @vpc_id ||= begin
          connection.subnets.get(locate_config_value(:subnet_id)).vpc_id
        end
      end

      def wait_for_nic_attachment
        attached_nics_count = 0
        until attached_nics_count ==
              locate_config_value(:network_interfaces).count
          attachment_nics =
            locate_config_value(:network_interfaces).map do |nic_id|
              connection.network_interfaces.get(nic_id).attachment['status']
            end
          attached_nics_count = attachment_nics.grep('attached').count
        end
      end

      def attach_nics
        attachments = []
        config[:network_interfaces].each_with_index do |nic_id, index|
          attachments << connection.attach_network_interface(nic_id,
                                                             server.id,
                                                             index + 1).body
        end
        wait_for_nic_attachment
        # rubocop:disable Style/RedundantReturn
        return attachments
        # rubocop:enable Style/RedundantReturn
      end

      def enable_classic_link(vpc_id, security_group_ids)
        connection.attach_classic_link_vpc(server.id, vpc_id, security_group_ids)
      end

      def ssh_override_winrm
        # unchanged ssh_user and changed winrm_user, override ssh_user
        if locate_config_value(:ssh_user).eql?(options[:ssh_user][:default]) &&
            !locate_config_value(:winrm_user).eql?(options[:winrm_user][:default])
          config[:ssh_user] = locate_config_value(:winrm_user)
        end
        # unchanged ssh_port and changed winrm_port, override ssh_port
        if locate_config_value(:ssh_port).eql?(options[:ssh_port][:default]) &&
            !locate_config_value(:winrm_port).eql?(options[:winrm_port][:default])
          config[:ssh_port] = locate_config_value(:winrm_port)
        end
        # unset ssh_password and set winrm_password, override ssh_password
        if locate_config_value(:ssh_password).nil? &&
            !locate_config_value(:winrm_password).nil?
          config[:ssh_password] = locate_config_value(:winrm_password)
        end
        # unset identity_file and set kerberos_keytab_file, override identity_file
        if locate_config_value(:identity_file).nil? &&
            !locate_config_value(:kerberos_keytab_file).nil?
          config[:identity_file] = locate_config_value(:kerberos_keytab_file)
        end
      end

      def tcp_test_winrm(ip_addr, port)
        tcp_socket = TCPSocket.new(ip_addr, port)
        yield
        true
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      rescue Errno::ENETUNREACH
        sleep 2
        false
        ensure
        tcp_socket && tcp_socket.close
      end

      def tcp_test_ssh(hostname, ssh_port)
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          ssh_banner = tcp_socket.gets
          if ssh_banner.nil? or ssh_banner.empty?
            false
          else
            Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{ssh_banner}")
            yield
            true
          end
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ENOTCONN, IOError
        Chef::Log.debug("ssh failed to connect: #{hostname}")
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        Chef::Log.debug("ssh timed out: #{hostname}")
        false
      # This happens on some mobile phone networks
      rescue Errno::ECONNRESET
        Chef::Log.debug("ssh reset its connection: #{hostname}")
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def decrypt_admin_password(encoded_password, key)
        require 'base64'
        require 'openssl'
        private_key = OpenSSL::PKey::RSA.new(key)
        encrypted_password = Base64.decode64(encoded_password)
        password = private_key.private_decrypt(encrypted_password)
        password
      end

      def check_windows_password_available(server_id)
        response = connection.get_password_data(server_id)
        if not response.body["passwordData"]
          return false
        end
        response.body["passwordData"]
      end

      def windows_password
        if not locate_config_value(:winrm_password)
          if locate_config_value(:identity_file)
            print "\n#{ui.color("Waiting for Windows Admin password to be available", :magenta)}"
            print(".") until check_windows_password_available(@server.id) {
              sleep 1000 #typically is available after 30 mins
              puts("done")
            }
            response = connection.get_password_data(@server.id)
            data = File.read(locate_config_value(:identity_file))
            config[:winrm_password] = decrypt_admin_password(response.body["passwordData"], data)
          else
            ui.error("Cannot find SSH Identity file, required to fetch dynamically generated password")
            exit 1
          end
        else
          locate_config_value(:winrm_password)
        end
      end

      def load_winrm_deps
        require 'winrm'
        require 'chef/knife/winrm'
        require 'chef/knife/bootstrap_windows_winrm'
        require 'chef/knife/bootstrap_windows_ssh'
        require 'chef/knife/core/windows_bootstrap_context'
      end
    end
  end
end
