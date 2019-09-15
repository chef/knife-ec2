#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2010-2019 Chef Software, Inc.
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

require "chef/knife/ec2_base"
require "chef/knife/s3_source"
require "chef/knife/bootstrap"

class Chef
  class Knife
    class Ec2ServerCreate < Chef::Knife::Bootstrap

      include Knife::Ec2Base

      deps do
        require "tempfile"
        require "uri"
        require "net/ssh"
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server create (options)"

      attr_accessor :initial_sleep_delay
      attr_reader :server

      option :flavor,
        short: "-f FLAVOR",
        long: "--flavor FLAVOR",
        description: "The flavor of server (m1.small, m1.medium, etc)",
        proc: Proc.new { |f| Chef::Config[:knife][:flavor] = f }

      option :image,
        short: "-I IMAGE",
        long: "--image IMAGE",
        description: "The AMI for the server",
        proc: Proc.new { |i| Chef::Config[:knife][:image] = i }

      option :iam_instance_profile,
        long: "--iam-profile NAME",
        description: "The IAM instance profile to apply to this instance."

      option :security_groups,
        short: "-G X,Y,Z",
        long: "--groups X,Y,Z",
        description: "The security groups for this server; not allowed when using VPC",
        proc: Proc.new { |groups| groups.split(",") }

      option :security_group_id,
        short: "-g SECURITY_GROUP_ID",
        long: "--security-group-id ID",
        description: "The security group id for this server; required when using VPC. Use the --security-group-id option multiple times when specifying multiple groups for e.g. -g sg-e985168d -g sg-e7f06383 -g sg-ec1b7e88.",
        proc: Proc.new { |security_group_id|
          Chef::Config[:knife][:security_group_ids] ||= []
          Chef::Config[:knife][:security_group_ids].push(security_group_id)
          Chef::Config[:knife][:security_group_ids]
        }

      option :associate_eip,
        long: "--associate-eip IP_ADDRESS",
        description: "Associate existing elastic IP address with instance after launch"

      option :dedicated_instance,
        long: "--dedicated_instance",
        description: "Launch as a Dedicated instance (VPC ONLY)"

      option :placement_group,
        long: "--placement-group PLACEMENT_GROUP",
        description: "The placement group to place a cluster compute instance",
        proc: Proc.new { |pg| Chef::Config[:knife][:placement_group] = pg }

      option :primary_eni,
        long: "--primary-eni ENI_ID",
        description: "Specify a pre-existing eni to use when building the instance."

      option :availability_zone,
        short: "-Z ZONE",
        long: "--availability-zone ZONE",
        description: "The Availability Zone",
        proc: Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :ssh_key_name,
        short: "-S KEY",
        long: "--ssh-key KEY",
        description: "The AWS SSH key id",
        proc: Proc.new { |key| Chef::Config[:knife][:ssh_key_name] = key }

      option :ebs_size,
        long: "--ebs-size SIZE",
        description: "The size of the EBS volume in GB, for EBS-backed instances"

      option :ebs_optimized,
        long: "--ebs-optimized",
        description: "Enabled optimized EBS I/O"

      option :ebs_no_delete_on_term,
        long: "--ebs-no-delete-on-term",
        description: "Do not delete EBS volume on instance termination"

      option :secret,
        long: "--secret ",
        description: "The secret key to use to encrypt data bag item values",
        proc: lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        long: "--secret-file SECRET_FILE",
        description: "A file containing the secret key to use to encrypt data bag item values",
        proc: lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :s3_secret,
        long: "--s3-secret S3_SECRET_URL",
        description: "S3 URL (e.g. s3://bucket/file) for the encrypted_data_bag_secret_file",
        proc: lambda { |url| Chef::Config[:knife][:s3_secret] = url }

      option :subnet_id,
        long: "--subnet SUBNET-ID",
        description: "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
        proc: Proc.new { |key| Chef::Config[:knife][:subnet_id] = key }

      option :private_ip_address,
        long: "--private-ip-address IP-ADDRESS",
        description: "allows to specify the private IP address of the instance in VPC mode",
        proc: Proc.new { |ip| Chef::Config[:knife][:private_ip_address] = ip }

      option :fqdn,
        long: "--fqdn FQDN",
        description: "Pre-defined FQDN. This is used for Kerberos Authentication purpose only",
        proc: Proc.new { |key| Chef::Config[:knife][:fqdn] = key },
        default: nil

      option :aws_user_data,
        long: "--user-data USER_DATA_FILE",
        short: "-u USER_DATA_FILE",
        description: "The EC2 User Data file to provision the instance with",
        proc: Proc.new { |m| Chef::Config[:knife][:aws_user_data] = m },
        default: nil

      option :ephemeral,
        long: "--ephemeral EPHEMERAL_DEVICES",
        description: "Comma separated list of device locations (eg - /dev/sdb) to map ephemeral devices",
        proc: lambda { |o| o.split(/[\s,]+/) },
        default: []

      option :server_connect_attribute,
        long: "--server-connect-attribute ATTRIBUTE",
        short: "-a ATTRIBUTE",
        description: "The EC2 server attribute to use for the SSH connection if necessary, e.g. public_ip_address or private_ip_address.",
        default: nil

      option :associate_public_ip,
        long: "--associate-public-ip",
        description: "Associate public ip to VPC instance.",
        boolean: true,
        default: false

      option :ebs_volume_type,
        long: "--ebs-volume-type TYPE",
        description: "Possible values are standard (magnetic) | io1 | gp2 | sc1 | st1. Default is gp2",
        proc: Proc.new { |key| Chef::Config[:knife][:ebs_volume_type] = key },
        default: "gp2"

      option :ebs_provisioned_iops,
        long: "--provisioned-iops IOPS",
        description: "IOPS rate, only used when ebs volume type is 'io1'",
        proc: Proc.new { |key| Chef::Config[:knife][:provisioned_iops] = key },
        default: nil

      option :validation_key_url,
        long: "--validation-key-url URL",
        description: "Path to the validation key",
        proc: proc { |m| Chef::Config[:validation_key_url] = m }

      option :ebs_encrypted,
        long: "--ebs-encrypted",
        description: "Enables EBS volume encryption",
        boolean: true,
        default: false

      option :spot_price,
        long: "--spot-price PRICE",
        description: "The maximum hourly USD price for the instance",
        default: nil

      option :spot_request_type,
        long: "--spot-request-type TYPE",
        description: "The Spot Instance request type. Possible values are 'one-time' and 'persistent', default value is 'one-time'",
        default: "one-time"

      option :spot_wait_mode,
        long: "--spot-wait-mode MODE",
        description:           "Whether we should wait for spot request fulfillment. Could be 'wait', 'exit', or " \
          "'prompt' (default). For any of the above mentioned choices, ('wait') - if the " \
          "instance does not get allocated before the command itself times-out or ('exit') the " \
          "user needs to manually bootstrap the instance in the future after it gets allocated.",
        default: "prompt"

      option :aws_connection_timeout,
        long: "--aws-connection-timeout MINUTES",
        description: "The maximum time in minutes to wait to for aws connection. Default is 10 min",
        proc: proc { |t| t = t.to_i * 60; Chef::Config[:aws_connection_timeout] = t },
        default: 600

      option :create_ssl_listener,
        long: "--[no-]create-ssl-listener",
        description: "Create ssl listener, enabled by default.",
        boolean: true,
        default: true

      option :network_interfaces,
        short: "-n",
        long: "--attach-network-interface ENI_ID1,ENI_ID2",
        description: "Attach additional network interfaces during bootstrap",
        proc: proc { |nics| nics.split(",") }

      option :classic_link_vpc_id,
        long: "--classic-link-vpc-id VPC_ID",
        description: "Enable ClassicLink connection with a VPC"

      option :classic_link_vpc_security_group_ids,
        long: "--classic-link-vpc-security-groups-ids X,Y,Z",
        description: "Comma-separated list of security group ids for ClassicLink",
        proc: Proc.new { |groups| groups.split(",") }

      option :disable_api_termination,
        long: "--disable-api-termination",
        description: "Disable termination of the instance using the Amazon EC2 console, CLI and API.",
        boolean: true,
        default: false

      option :disable_source_dest_check,
        long: "--disable-source-dest-check",
        description: "Disables the source destination check if this option is passed. This value must be passed for a NAT instance to perform NAT.",
        boolean: true,
        default: false

      option :volume_tags,
        long: "--volume-tags Tag=Value[,Tag=Value...]",
        description: "Tag the Root volume",
        proc: Proc.new { |volume_tags| volume_tags.split(",") }

      option :instance_initiated_shutdown_behavior,
        long: "--instance-initiated-shutdown-behavior SHUTDOWN_BEHAVIOR",
        description: "Indicates whether an instance stops or terminates when you initiate shutdown from the instance. Possible values are 'stop' and 'terminate', default is 'stop'."

      option :chef_tag,
        long: "--chef-tag CHEF_TAG",
        description: "Use to tag the node in chef server; Provide --chef-tag option multiple times when specifying multiple tags e.g. --chef-tag tag1 --chef-tag tag2.",
        proc: Proc.new { |chef_tag|
          Chef::Config[:knife][:chef_tag] ||= []
          Chef::Config[:knife][:chef_tag].push(chef_tag)
          Chef::Config[:knife][:chef_tag]
        }

      option :aws_tag,
        long: "--aws-tag AWS_TAG",
        description: "AWS tag for this server; Use the --aws-tag option multiple times when specifying multiple tags e.g. --aws-tag key1=value1 --aws-tag key2=value2.",
        proc: Proc.new { |aws_tag|
          Chef::Config[:knife][:aws_tag] ||= []
          Chef::Config[:knife][:aws_tag].push(aws_tag)
          Chef::Config[:knife][:aws_tag]
        }

      option :cpu_credits,
        long: "--cpu-credits CPU_CREDITS",
        description: "The credit option for CPU usage of the instance. Valid values are standard and unlimited. T3 instances launch as unlimited by default. T2 instances launch as standard by default.",
        default: "standard",
        in: %w{standard unlimited}

      def plugin_create_instance!
        requested_elastic_ip = config[:associate_eip] if config[:associate_eip]

        # For VPC EIP assignment we need the allocation ID so fetch full EIP details
        elastic_ip = ec2_connection.describe_addresses.addresses.detect { |addr| addr if addr.public_ip == requested_elastic_ip }

        if config_value(:spot_price)
          server_def = spot_instances_attributes
          spot_request = ec2_connection.request_spot_instances(server_def)
          msg_pair("Spot Request ID", spot_request.spot_instance_request_id)
          msg_pair("Spot Request Type", spot_request.type)
          msg_pair("Spot Price", spot_request.spot_price)

          case config[:spot_wait_mode]
          when "prompt", "", nil
            wait_msg = "Do you want to wait for Spot Instance Request fulfillment? (Y/N) \n"
            wait_msg += "Y - Wait for Spot Instance request fulfillment\n"
            wait_msg += "N - Do not wait for Spot Instance request fulfillment. "
            wait_msg += ui.color("[WARN :: Request would be alive on AWS ec2 side but execution of Chef Bootstrap on the target instance will get skipped.]\n", :red, :bold)
            wait_msg += ui.color("\n[WARN :: For any of the above mentioned choices, (Y) - if the instance does not get allocated before the command itself times-out or (N) - user decides to exit, then in both cases user needs to manually bootstrap the instance in the future after it gets allocated.]\n\n", :cyan, :bold)
            confirm(wait_msg)
          when "wait"
            # wait for the node and run Chef bootstrap
          when "exit"
            ui.color("The 'exit' option was specified for --spot-wait-mode, exiting.", :cyan)
            exit
          else
            raise "Invalid value for --spot-wait-mode: '#{config[:spot_wait_mode]}', " \
              "valid values: wait, exit, prompt"
          end

          print ui.color("Waiting for Spot Request fulfillment:  ", :cyan)
          spot_response = spot_instances_wait_until_ready(spot_request.spot_instance_request_id)

          @server = fetch_ec2_instance(spot_response.instance_id)
        else
          begin
            response_obj = create_ec2_instance(server_attributes)
            instance_id = response_obj.instances[0].instance_id
            print "\n#{ui.color("Waiting for EC2 to create the instance\n", :magenta)}"

            # wait for instance to come up before acting against it
            instances_wait_until_ready(instance_id)
            @server = fetch_ec2_instance(instance_id)
          rescue => error
            error.message.sub("download completed, but downloaded file not found", "Verify that you have public internet access.")
            ui.error error.message
            Chef::Log.debug("#{error.backtrace.join("\n")}")
            exit
          end
        end
        msg_pair("Instance ID", server.id)
        msg_pair("Flavor", server.instance_type)
        msg_pair("Image", server.image_id)
        msg_pair("Region", fetch_region)
        msg_pair("Availability Zone", server.availability_zone)
        msg_pair("Security Groups", printed_security_groups) unless vpc_mode? || (server.groups && server.security_groups_ids)
        msg_pair("Security Group Ids", printed_security_group_ids) if vpc_mode? || server.security_groups_ids

        msg_pair("IAM Profile", config_value(:iam_instance_profile))

        msg_pair("AWS Tags", printed_aws_tags)
        msg_pair("Volume Tags", printed_volume_tags)
        msg_pair("SSH Key", server.key_name)
        msg_pair("T2/T3 Unlimited", printed_t2_t3_unlimited)

        puts("\n")

        # occasionally 'ready?' isn't, so retry a couple times if needed.
        tries = 6
        begin
          disable_source_dest_check if vpc_mode? && config_value(:disable_source_dest_check)

          create_tags(hashed_tags) unless hashed_tags.empty?
          create_volume_tags(hashed_volume_tags) unless hashed_volume_tags.empty?
          associate_address(elastic_ip) if config[:associate_eip]
          enable_classic_link(config[:classic_link_vpc_id], config[:classic_link_vpc_security_group_ids]) if config[:classic_link_vpc_id]
        rescue Aws::EC2::Errors::ServiceError, Aws::EC2::Errors::Error
          raise if (tries -= 1) <= 0

          ui.warn("server not ready, retrying tag application (retries left: #{tries})")
          sleep 5
          retry
        end

        attach_nics if config[:network_interfaces]

        # Re-fetch the latest server data after assigning vpc or network interfaces
        @server = fetch_ec2_instance(instance_id) if reload_server_data_required?

        if vpc_mode?
          msg_pair("Subnet ID", server.subnet_id)
          msg_pair("Tenancy", server.tenancy)
          if config[:associate_public_ip]
            msg_pair("Public DNS Name", server.public_dns_name)
          end
          if elastic_ip
            msg_pair("Public IP Address", server.public_ip_address)
          end
        else
          msg_pair("Public DNS Name", server.public_dns_name)
          msg_pair("Public IP Address", server.public_ip_address)
          msg_pair("Private DNS Name", server.private_dns_name)
        end
        msg_pair("Private IP Address", server.private_ip_address)

        if Chef::Config[:knife][:validation_key_url]
          download_validation_key(validation_key_path)
          Chef::Config[:validation_key] = validation_key_path
        end

        config[:connection_protocol] ||= connection_protocol
        config[:connection_port] ||= connection_port

        # Check if Server is Windows or Linux
        if is_image_windows?
          if winrm?
            print "\n#{ui.color("Waiting for winrm access to become available", :magenta)}"
            print(".") until tcp_test_winrm(connection_host, connection_port) do
              sleep 10
              puts("done")
            end
          else
            print "\n#{ui.color("Waiting for sshd access to become available", :magenta)}"
            # If FreeSSHd, winsshd etc are available
            print(".") until tcp_test_ssh(connection_host, connection_port) do
              sleep @initial_sleep_delay ||= (vpc_mode? ? 40 : 10)
              puts("done")
            end
          end
        else
          print "\n#{ui.color("Waiting for sshd access to become available", :magenta)}"
          wait_for_sshd(connection_host)
        end

        fqdn = connection_host
        if winrm?
          if config_value(:kerberos_realm)
            # Fetch AD/WINS based fqdn if any for Kerberos-based Auth
            fqdn = config_value(:fqdn) || fetch_server_fqdn(server.private_ip_address)
          end
          config[:connection_password] = windows_password
        end
        @name_args = [fqdn]

        if config_value(:chef_node_name)
          config[:chef_node_name] = evaluate_node_name(config_value(:chef_node_name))
        else
          config[:chef_node_name] = server.id
        end
        bootstrap_common_params
      end

      def plugin_finalize
        puts "\n"
        msg_pair("Instance ID", server.id)
        msg_pair("Flavor", server.instance_type)
        msg_pair("Placement Group", server.placement_group) unless server.placement_group.nil?
        msg_pair("Image", server.image_id)
        msg_pair("Region", fetch_region)
        msg_pair("Availability Zone", server.availability_zone)
        msg_pair("Security Groups", printed_security_groups) unless vpc_mode? || (server.groups.nil? && server.security_group_ids)
        msg_pair("Security Group Ids", printed_security_group_ids) if vpc_mode? || server.security_group_ids
        msg_pair("IAM Profile", config_value(:iam_instance_profile)) if config_value(:iam_instance_profile)
        msg_pair("Primary ENI", config_value(:primary_eni)) if config_value(:primary_eni)
        msg_pair("AWS Tags", printed_aws_tags)
        msg_pair("Chef Tags", config_value(:tags)) if config_value(:tags).any?
        msg_pair("SSH Key", server.key_name)
        msg_pair("Root Device Type", server.root_device_type)
        msg_pair("Root Volume Tags", printed_volume_tags)
        if server.root_device_type == "ebs"
          device_map = server.block_device_mappings.first
          msg_pair("Root Device Name", device_map.device_name)
          msg_pair("Root Volume ID", device_map.ebs.volume_id)
          msg_pair("Root Device Delete on Terminate", device_map.ebs.delete_on_termination)
          msg_pair("Standard or Provisioned IOPS", device_map.ebs.volume_type) if device_map.ebs.respond_to?("volume_type")
          msg_pair("IOPS rate", device_map.ebs.iops) if device_map.ebs.respond_to?("iops")

          print "\n#{ui.color("Block devices", :magenta)}\n"
          print "#{ui.color("===========================", :magenta)}\n"
          server.block_device_mappings.each do |device_map|
            msg_pair("Device Name", device_map.device_name)
            msg_pair("Volume ID", device_map.ebs.volume_id)
            msg_pair("Delete on Terminate", device_map.ebs.delete_on_termination.to_s)
            msg_pair("Standard or Provisioned IOPS", device_map.ebs.volume_type) if device_map.ebs.respond_to?("volume_type")
            msg_pair("IOPS rate", device_map.ebs.iops) if device_map.ebs.respond_to?("iops")
            print "\n"
          end
          print "#{ui.color("===========================", :magenta)}\n"

          if config[:ebs_size]
            volume_size = ami.block_device_mappings[0].ebs.volume_size
            if volume_size.to_i < config[:ebs_size].to_i
              volume_too_large_warning = "#{config[:ebs_size]}GB " +
                "EBS volume size is larger than size set in AMI of " +
                "#{volume_size}GB.\n" +
                "Use file system tools to make use of the increased volume size."
              msg_pair("Warning", volume_too_large_warning, :yellow)
            end
          end
        end
        if config[:ebs_optimized]
          msg_pair("EBS is Optimized", server.ebs_optimized.to_s)
        end
        if vpc_mode?
          msg_pair("Subnet ID", server.subnet_id)
          msg_pair("Tenancy", server.tenancy)
          if config[:associate_public_ip]
            msg_pair("Public DNS Name", server.public_dns_name)
          end
        else
          msg_pair("Public DNS Name", server.public_dns_name)
          msg_pair("Public IP Address", server.public_ip_address)
          msg_pair("Private DNS Name", server.private_dns_name)
        end
        msg_pair("Private IP Address", server.private_ip_address)
        msg_pair("Environment", config[:environment] || "_default")
        msg_pair("Run List", (config[:run_list] || []).join(", "))
        if config[:first_boot_attributes] || config[:first_boot_attributes_from_file]
          msg_pair("JSON Attributes", config[:first_boot_attributes] || config[:first_boot_attributes_from_file])
        end
      end

      # return the default bootstrap template based on platform
      # @return [String]
      def default_bootstrap_template
        is_image_windows? ? "windows-chef-client-msi" : "chef-full"
      end

      def validation_key_path
        @validation_key_path ||= begin
          if URI(Chef::Config[:knife][:validation_key_url]).scheme == "file"
            URI(Chef::Config[:knife][:validation_key_url]).path
          else
            validation_key_tmpfile.path
          end
        end
      end

      # @return [Tempfile]
      def validation_key_tmpfile
        @validation_key_tmpfile ||= Tempfile.new("validation_key")
      end

      def download_validation_key(tempfile)
        Chef::Log.debug "Downloading validation key " \
          "<#{Chef::Config[:knife][:validation_key_url]}> to file " \
          "<#{tempfile}>"

        case URI(Chef::Config[:knife][:validation_key_url]).scheme
        when "s3"
          File.open(tempfile, "w") { |f| f.write(s3_validation_key) }
        end
      end

      def s3_validation_key
        @s3_validation_key ||= begin
          Chef::Knife::S3Source.fetch(Chef::Config[:knife][:validation_key_url])
        end
      end

      def s3_secret
        @s3_secret ||= begin
          return false unless config_value(:s3_secret)

          Chef::Knife::S3Source.fetch(config_value(:s3_secret))
        end
      end

      def bootstrap_common_params
        config[:encrypted_data_bag_secret] = s3_secret || config_value(:secret)
        config[:encrypted_data_bag_secret_file] = config_value(:secret_file)
        # retrieving the secret from S3 is unique to knife-ec2, so we need to set "command line secret" to the value fetched from S3
        # When linux vm is spawned, the chef's secret option proc function sets the value "command line secret" and this value is used by
        # chef's code to check if secret option is passed through command line or not
        Chef::Knife::DataBagSecretOptions.set_cl_secret(s3_secret) if config_value(:s3_secret)
        config[:secret] = s3_secret || config_value(:secret)

        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["ec2"] ||= {}
      end

      def fetch_server_fqdn(ip_addr)
        require "resolv"
        Resolv.getname(ip_addr)
      end

      def vpc_mode?
        # Amazon Virtual Private Cloud requires a subnet_id. If
        # present, do a few things differently
        !!config_value(:subnet_id)
      end

      def validate_name_args!
        # We don't know the name of our instance yet
      end

      def plugin_validate_options!
        if Chef::Config[:knife].keys.include? :aws_ssh_key_id
          Chef::Config[:knife][:ssh_key_name] = Chef::Config[:knife][:aws_ssh_key_id] unless Chef::Config[:knife][:ssh_key_name]
          Chef::Config[:knife].delete(:aws_ssh_key_id)
          ui.warn("Use of aws_ssh_key_id option in knife.rb/config.rb config is deprecated, use ssh_key_name option instead.")
        end
        create_key_pair unless config_value(:ssh_key_name)

        validate_aws_config!(%i{image ssh_key_name aws_access_key_id aws_secret_access_key})

        validate_nics! if config_value(:network_interfaces)

        if ami.nil?
          ui.error("The provided AMI value '#{config_value(:image)}' could not be found. Is this AMI availble in the provided region #{config_value(:region)}?")
          exit 1
        end

        if vpc_mode? && !!config[:security_groups]
          ui.error("You are using a VPC, security groups specified with '-G' are not allowed, specify one or more security group ids with '-g' instead.")
          exit 1
        end

        if !vpc_mode? && !!config[:private_ip_address]
          ui.error("You can only specify a private IP address if you are using VPC.")
          exit 1
        end

        if config[:dedicated_instance] && !vpc_mode?
          ui.error("You can only specify a Dedicated Instance if you are using VPC.")
          exit 1
        end

        if !vpc_mode? && config[:associate_public_ip]
          ui.error("--associate-public-ip option only applies to VPC instances, and you have not specified a subnet id.")
          exit 1
        end

        if config[:associate_eip]
          eips = ec2_connection.describe_addresses.addresses.collect { |addr| addr if addr.domain == eip_scope }.compact

          unless eips.detect { |addr| addr.public_ip == config[:associate_eip] && addr.instance_id.nil? }
            ui.error("Elastic IP requested is not available.")
            exit 1
          end
        end

        if config[:ebs_provisioned_iops] && (config[:ebs_volume_type] != "io1")
          ui.error("--provisioned-iops option is only supported for volume type of 'io1'")
          exit 1
        end

        if (config[:ebs_volume_type] == "io1") && config[:ebs_provisioned_iops].nil?
          ui.error("--provisioned-iops option is required when using volume type of 'io1'")
          exit 1
        end

        if config[:ebs_volume_type] && ! %w{gp2 io1 standard}.include?(config[:ebs_volume_type])
          ui.error("--ebs-volume-type must be 'standard' or 'io1' or 'gp2'")
          msg opt_parser
          exit 1
        end

        if config[:security_groups] && config[:security_groups].class == String
          ui.error("Invalid value type for knife[:security_groups] in knife configuration file (i.e knife.rb/config.rb). Type should be array. e.g - knife[:security_groups] = ['sgroup1']")
          exit 1
        end

        # Validation for security_group_ids passed through knife.rb/config.rb. It will raise error if values are not provided in Array.
        if config_value(:security_group_ids) && config_value(:security_group_ids).class == String
          ui.error("Invalid value type for knife[:security_group_ids] in knife configuration file (i.e knife.rb/config.rb). Type should be array. e.g - knife[:security_group_ids] = ['sgroup1']")
          exit 1
        end

        if config[:classic_link_vpc_id].nil? ^ config[:classic_link_vpc_security_group_ids].nil?
          ui.error("--classic-link-vpc-id and --classic-link-vpc-security-group-ids must be used together")
          exit 1
        end

        if vpc_mode? && config[:classic_link_vpc_id]
          ui.error("You can only use ClassicLink if you are not using a VPC")
          exit 1
        end

        if config_value(:ebs_encrypted)
          error_message = ""
          errors = []
          # validation for flavor and ebs_encrypted
          if !config_value(:flavor)
            ui.error("--ebs-encrypted option requires valid flavor to be specified.")
            exit 1
          elsif config_value(:ebs_encrypted) && ! %w{m3.medium m3.large m3.xlarge m3.2xlarge m4.large m4.xlarge
                                             m4.2xlarge m4.4xlarge m4.10xlarge m4.16xlarge t2.nano t2.micro t2.small
                                             t2.medium t2.large t2.xlarge t2.2xlarge d2.xlarge d2.2xlarge d2.4xlarge
                                             d2.8xlarge c4.large c4.xlarge c4.2xlarge c4.4xlarge c4.8xlarge c3.large
                                             c3.xlarge c3.2xlarge c3.4xlarge c3.8xlarge cr1.8xlarge r3.large r3.xlarge
                                             r3.2xlarge r3.4xlarge r3.8xlarge r4.large r4.xlarge r4.2xlarge r4.4xlarge
                                             r4.8xlarge r4.16xlarge x1.16xlarge x1.32xlarge i2.xlarge i2.2xlarge i2.4xlarge
                                             i2.8xlarge i3.large i3.xlarge i3.2xlarge i3.4xlarge i3.8xlarge i3.16xlarge
                                             f1.2xlarge f1.16xlarge g2.2xlarge g2.8xlarge p2.xlarge p2.8xlarge p2.16xlarge}.include?(config_value(:flavor))
            ui.error("--ebs-encrypted option is not supported for #{config_value(:flavor)} flavor.")
            exit 1
          end

          # validation for ebs_size and ebs_volume_type and ebs_encrypted
          if !config_value(:ebs_size)
            errors << "--ebs-encrypted option requires valid --ebs-size to be specified."
          elsif (config_value(:ebs_volume_type) == "gp2") && ! config_value(:ebs_size).to_i.between?(1, 16384)
            errors << "--ebs-size should be in between 1-16384 for 'gp2' ebs volume type."
          elsif (config_value(:ebs_volume_type) == "io1") && ! config_value(:ebs_size).to_i.between?(4, 16384)
            errors << "--ebs-size should be in between 4-16384 for 'io1' ebs volume type."
          elsif (config_value(:ebs_volume_type) == "standard") && ! config_value(:ebs_size).to_i.between?(1, 1024)
            errors << "--ebs-size should be in between 1-1024 for 'standard' ebs volume type."
          end

          if errors.each { |e| error_message = "#{error_message} #{e}" }.any?
            ui.error(error_message)
            exit 1
          end
        end

        if config_value(:spot_price) && config_value(:disable_api_termination)
          ui.error("spot-price and disable-api-termination options cannot be passed together as 'Termination Protection' cannot be enabled for spot instances.")
          exit 1
        end

        if config_value(:spot_price).nil? && config_value(:spot_wait_mode)
          unless config_value(:spot_wait_mode).casecmp("prompt") == 0
            ui.error("spot-wait-mode option requires that a spot-price option is set.")
            exit 1
          end
        end

        volume_tags = config_value(:volume_tags)
        if !volume_tags.nil? && (volume_tags.length != volume_tags.to_s.count("="))
          ui.error("Volume Tags should be entered in a key = value pair")
          exit 1
        end

        if winrm? && config_value(:connection_password).to_s.length > 14
          ui.warn("The password provided is longer than 14 characters. Computers with Windows prior to Windows 2000 will not be able to use this account. Do you want to continue this operation? (Y/N):")
          password_promt = STDIN.gets.chomp.upcase
          if password_promt == "N"
            raise "Exiting as operation with password greater than 14 characters not accepted"
          elsif password_promt == "Y"
            @allow_long_password = "/yes"
          else
            raise "The input provided is incorrect."
          end
        end

        if config_value(:chef_tag)
          # If --chef-tag is provided then it will be set in chef as single value e.g. --chef-tag "myTag"
          # --tags has been removed from knife-ec2, now it's available in core
          config[:tags] += config_value(:chef_tag)
          ui.warn("[DEPRECATED] --chef-tag option is deprecated and will be removed in future release. Use --tags TAGS option instead.")
        end

        if config_value(:cpu_credits) && !config_value(:flavor)
          ui.error("Instance type should be specified and should be any of T2/T3 type.")
          exit 1
        end
      end

      def parse_aws_tags
        tags = config_value(:aws_tag)
        if !tags.nil? && (tags.length != tags.to_s.count("="))
          ui.error("AWS Tags should be entered in a key = value pair")
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
        user_related_commands = ""
        user = connection_user.split("\\")
        if (user[0] == ".") || (user[0] == "") || (user.length == 1)
          user_related_commands = <<~EOH
            net user /add #{connection_user.delete('.\\')} #{windows_password} #{@allow_long_password};
            net localgroup Administrators /add #{connection_user.delete('.\\')};
          EOH
        end
        <<~EOH
          #{user_related_commands}
          If (-Not (Get-Service WinRM | Where-Object {$_.status -eq "Running"})) {
            winrm quickconfig -q
          }
          If (winrm e winrm/config/listener | Select-String -Pattern " Transport = HTTP\\b" -Quiet) {
            winrm delete winrm/config/listener?Address=*+Transport=HTTP
          }
          $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/public-ipv4
          If (-Not $vm_name) {
            $vm_name = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/local-ipv4
          }

          $name = new-object -com "X509Enrollment.CX500DistinguishedName.1"
          $name.Encode("CN=$vm_name", 0)
          $key = new-object -com "X509Enrollment.CX509PrivateKey.1"
          $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
          $key.KeySpec = 1
          $key.Length = 2048
          $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
          $key.MachineContext = 1
          $key.Create()
          $serverauthoid = new-object -com "X509Enrollment.CObjectId.1"
          $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
          $ekuoids = new-object -com "X509Enrollment.CObjectIds.1"
          $ekuoids.add($serverauthoid)
          $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
          $ekuext.InitializeEncode($ekuoids)
          $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
          $cert.InitializeFromPrivateKey(2, $key, "")
          $cert.Subject = $name
          $cert.Issuer = $cert.Subject
          $cert.NotBefore = get-date
          $cert.NotAfter = $cert.NotBefore.AddYears(10)
          $cert.X509Extensions.Add($ekuext)
          $cert.Encode()
          $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1"
          $enrollment.InitializeFromRequest($cert)
          $certdata = $enrollment.CreateRequest(0)
          $enrollment.InstallResponse(2, $certdata, 0, "")

          $thumbprint = (Get-ChildItem -Path cert:\\localmachine\\my | Where-Object {$_.Subject -match "$vm_name"}).Thumbprint;
          $create_listener_cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname=`"$vm_name`";CertificateThumbprint=`"$thumbprint`"}'"
          iex $create_listener_cmd
          netsh advfirewall firewall add rule name="WinRM HTTPS" protocol=TCP dir=in Localport=5986 remoteport=any action=allow localip=any remoteip=any profile=any enable=yes
        EOH
      end

      def ssl_config_data_already_exist?
        File.read(config_value(:aws_user_data)).gsub(/\\\\/, "\\").include? ssl_config_user_data.strip
      end

      def process_user_data(script_lines)
        unless ssl_config_data_already_exist?
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
            script_lines.insert(-1, "\n\n" + ps_start_tag + ssl_config_user_data + ps_end_tag)
          end
        end
        script_lines
      end

      # base64-encoded text
      def encode_data(text)
        require "base64"
        Base64.encode64(text)
      end

      def spot_instances_attributes
        attributes = {
          instance_count: 1,
          launch_specification: server_attributes,
          spot_price: config_value(:spot_price),
          type: config_value(:spot_request_type),
        }
      end

      def server_attributes
        attributes = {
          image_id: config_value(:image),
          instance_type: config_value(:flavor),
          groups: config[:security_groups],
          key_name: config_value(:ssh_key_name),
          max_count: 1,
          min_count: 1,
          placement: {
            availability_zone: config_value(:availability_zone),
          },
        }

        network_attrs = {}
        if !!config_value(:primary_eni)
          network_attrs[:network_interface_id] = config_value(:primary_eni)
        elsif vpc_mode?
          network_attrs[:subnet_id] = config_value(:subnet_id)
        end

        if vpc_mode?
          network_attrs[:groups] = config_value(:security_group_ids) if !!config_value(:security_group_ids)
          network_attrs[:private_ip_address] = config_value(:private_ip_address)
          network_attrs[:associate_public_ip_address] = config_value(:associate_public_ip)
        end

        if network_attrs.length > 0
          network_attrs[:device_index] = 0
          attributes[:network_interfaces] = [network_attrs]
        else
          attributes[:security_group_ids] = config_value(:security_group_ids)
        end

        attributes[:placement][:group_name] = config_value(:placement_group)
        attributes[:placement][:tenancy] = "dedicated" if vpc_mode? && config_value(:dedicated_instance)
        attributes[:iam_instance_profile] = {}
        attributes[:iam_instance_profile][:name] = config_value(:iam_instance_profile)

        if config_value(:winrm_ssl)
          if config_value(:aws_user_data)
            begin
              user_data = File.readlines(config_value(:aws_user_data))
              if config[:create_ssl_listener]
                user_data = process_user_data(user_data)
              end
              user_data = user_data.join
              attributes.merge!(user_data: encode_data(user_data))
            rescue
              ui.warn("Cannot read #{config_value(:aws_user_data)}: #{$!.inspect}. Ignoring option.")
            end
          else
            if config[:create_ssl_listener]
              attributes[:user_data] = encode_data("<powershell>\n" + ssl_config_user_data + "</powershell>\n")
            end
          end
        else
          if config_value(:aws_user_data)
            begin
              user_data = File.read(config_value(:aws_user_data))
              attributes.merge!(user_data: encode_data(user_data))
            rescue
              ui.warn("Cannot read #{config_value(:aws_user_data)}: #{$!.inspect}. Ignoring option.")
            end
          end
        end

        attributes[:ebs_optimized] = !!config_value(:ebs_optimized)

        if ami.root_device_type == "ebs"
          if config_value(:ebs_encrypted)
            ami_map = ami.block_device_mappings[1]
          else
            ami_map = ami.block_device_mappings.first
          end

          ebs_size = begin
                       if config[:ebs_size]
                         Integer(config[:ebs_size]).to_s
                       else
                         ami_map.ebs.volume_size.to_s if ami_map.ebs.respond_to?(:volume_size)
                       end
                     rescue ArgumentError
                       puts "--ebs-size must be an integer"
                       msg opt_parser
                       exit 1
                     end
          delete_term = if config[:ebs_no_delete_on_term]
                          "false"
                        else
                          ami_map.ebs.delete_on_termination if ami_map.ebs.respond_to?(:delete_on_termination)
                        end
          iops_rate = begin
                        if config[:ebs_provisioned_iops]
                          Integer(config[:ebs_provisioned_iops]).to_s
                        else
                          ami_map.ebs.iops.to_s if ami_map.ebs.respond_to?(:iops)
                        end
                      rescue ArgumentError
                        puts "--provisioned-iops must be an integer"
                        msg opt_parser
                        exit 1
                      end

          attributes[:block_device_mappings] =
            [{
               device_name: ami_map.device_name,
               ebs: {
                  delete_on_termination: delete_term,
                  volume_size: ebs_size,
                  volume_type: config[:ebs_volume_type], # accepts standard, io1, gp2, sc1, st1
                },
             }]
          attributes[:block_device_mappings][0][:ebs][:iops] = iops_rate unless iops_rate.nil? || iops_rate.empty?
          attributes[:block_device_mappings][0][:ebs][:encrypted] = true if config_value(:ebs_encrypted)
        end

        if config[:ephemeral] && config[:ephemeral].length > 0
          ephemeral_blocks = []
          config[:ephemeral].each_with_index do |device_name, i|
            ephemeral_blocks << { virtual_name: "ephemeral#{i}", device_name: device_name, ebs: { volume_size: ebs_size } }
          end
          attributes[:block_device_mappings] += ephemeral_blocks
        end

        ## cannot pass disable_api_termination option to the API when using spot instances ##
        attributes[:disable_api_termination] = config_value(:disable_api_termination) if config_value(:spot_price).nil?

        attributes[:instance_initiated_shutdown_behavior] = config_value(:instance_initiated_shutdown_behavior)

        attributes[:credit_specification] =
          {
            cpu_credits: config[:cpu_credits],
          }
        attributes
      end

      def create_ec2_instance(attributes)
        ec2_connection.run_instances(attributes)
      end

      def spot_instances_wait_until_ready(spot_request_id)
        ec2_connection.wait_until(
          :spot_instance_request_fulfilled,
          spot_instance_request_ids: [spot_request_id]
        ).spot_instance_requests[0]
      rescue Aws::Waiters::Errors::WaiterFailed => error
        puts "failed waiting for spot request fulfill: #{error.message}"
      end

      def instances_wait_until_ready(instance_id)
        ec2_connection.wait_until(:instance_running, instance_ids: [instance_id]) do |w|
          w.max_attempts = max_attempts
        end
      rescue Aws::Waiters::Errors::WaiterFailed => error
        puts "failed waiting for instance running: #{error.message}"
      end

      def max_attempts
        delay = 15 # Default Delay for waiter
        attempts = 40 # Default max attempts for waiter

        if config_value(:aws_connection_timeout)
          attempts = (config_value(:aws_connection_timeout).to_f / delay).to_i
        end
        attempts
      end

      def wait_for_sshd(hostname)
        ssh_gateway = get_ssh_gateway_for(hostname)
        ssh_gateway ? wait_for_tunnelled_sshd(ssh_gateway, hostname) : wait_for_direct_sshd(hostname, connection_port)
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
        print(".") until tunnel_test_ssh(ssh_gateway, hostname) do
          if initial
            initial = false
            sleep (vpc_mode? ? 40 : 10)
          else
            sleep 10
          end
          puts("done")
        end
      end

      def tunnel_test_ssh(ssh_gateway, hostname, &block)
        status = false
        gateway = configure_ssh_gateway(ssh_gateway)
        gateway.open(hostname, connection_port) do |local_tunnel_port|
          status = tcp_test_ssh("localhost", local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def configure_ssh_gateway(ssh_gateway)
        gw_host, gw_user = ssh_gateway.split("@").reverse
        gw_host, gw_port = gw_host.split(":")
        gateway_options = { port: gw_port || 22 }

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
          gateway_keys = Array(config_value(:ssh_gateway_identity))
        end

        unless gateway_keys.nil?
          gateway_options[:keys] = gateway_keys
        end

        Net::SSH::Gateway.new(gw_host, gw_user, gateway_options)
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        initial = true
        print(".") until tcp_test_ssh(hostname, ssh_port) do
          if initial
            initial = false
            sleep (vpc_mode? ? 40 : 10)
          else
            sleep 10
          end
          puts("done")
        end
      end

      # @return [Boolean]
      def subnet_public_ip_on_launch?
        return false unless server.subnet_id

        subnet = fetch_subnet(server.subnet_id)
        subnet.map_public_ip_on_launch
      end

      # Assign connection host based on attribute passed
      # @return [String]
      def connection_host
        @connection_host ||= server.send(connect_attribute)

        puts "\nSSH Target Address: #{@connection_host}(#{connect_attribute})"
        @connection_host
      end

      # Identify connection attribute if:
      # Option --server-connect-attribute is set.
      # For VPC mode check if public IP or elastic IP has been requested.
      # Otherwise assign public DNS or public IP.
      # @return [String]
      def connect_attribute
        @connect_attribute ||= begin
          if !!config[:server_connect_attribute]
            config[:server_connect_attribute]
          elsif vpc_mode? && !(subnet_public_ip_on_launch? || config[:associate_public_ip] || config[:associate_eip])
            "private_ip_address"
          else
            server.public_dns_name ? "public_dns_name" : "public_ip_address"
          end
        end
      end

      def create_tags(hashed_tags)
        request_tags = []
        hashed_tags.each_pair do |key, val|
          request_tags << { key: key, value: val }
        end

        if request_tags.length > 0
          ec2_connection.create_tags(tags: request_tags, resources: [server.id])
        end
      end

      def create_volume_tags(hashed_volume_tags)
        request_tags = []
        hashed_volume_tags.each_pair do |key, val|
          request_tags << { key: key, value: val }
        end

        if request_tags.length > 0
          ec2_connection.create_tags(tags: request_tags, resources: [server.volume_id])
        end
      end

      def create_key_pair
        key_name = "#{config[:connection_user]}-#{SecureRandom.hex(10)}"
        key_pair = ec2_connection.create_key_pair({
          key_name: key_name,
        })

        save_keypair_file(key_pair) if key_pair
      end

      def save_keypair_file(key_pair)
        file_path = File.join(Config.config_dir, "#{key_pair.key_name}.pem")
        file = File.open(file_path, "w+") { |f| f << key_pair.key_material }

        Chef::Config[:knife][:ssh_key_name] = key_pair.key_name
        Chef::Config[:knife][:ssh_identity_file] = file.path
        puts "\nGenerated keypair file: #{file.path}"
      end

      def associate_address(elastic_ip)
        ec2_connection.associate_address({
          allocation_id: elastic_ip.allocation_id,
          instance_id: server.id,
        })
      end

      def validate_nics!
        params = {}
        if vpc_mode?
          network_attrs = { name: "vpc_id", value: [vpc_id] }
          params["filters"] = [network_attrs]
        end

        interfaces = ec2_connection.describe_network_interfaces(params)
        valid_nic_ids = interfaces.network_interfaces.map(&:network_interface_id)
        invalid_nic_ids = config_value(:network_interfaces) - valid_nic_ids

        return true if invalid_nic_ids.empty?

        ui.error "The following network interfaces are invalid: " \
          "#{invalid_nic_ids.join(", ")}"
        exit 1
      end

      def vpc_id
        @vpc_id ||= fetch_subnet(locate_config_value(:subnet_id)).vpc_id
      end

      def wait_for_nic_attachment
        attached_nics_count = 0
        until attached_nics_count == config_value(:network_interfaces).count
          attachment_nics =
            locate_config_value(:network_interfaces).map do |nic_id|
              fetch_network_interfaces(nic_id).attachment.status
            end
          attached_nics_count = attachment_nics.grep("attached").count
        end
      end

      def attach_nics
        attachments = []
        config[:network_interfaces].each_with_index do |nic_id, index|
          attachments << ec2_connection.attach_network_interface({
            device_index: index + 1,
            instance_id: server.id,
            network_interface_id: nic_id,
          })
        end
        wait_for_nic_attachment

        attachments
      end

      def enable_classic_link(vpc_id, security_group_ids)
        ec2_connection.attach_classic_link_vpc({
          instance_id: server.id,
          groups: security_group_ids,
          vpc_id: vpc_id,
        })
      end

      # disable_source_dest_check option is used to set value of source_dest_check attribute in ec2.
      # By default the source destination check is enabled in ec2.
      # This value must be disable for a NAT instance to perform NAT.
      def disable_source_dest_check
        ec2_connection.modify_instance_attribute({
          source_dest_check: {
            value: false,
          },
          instance_id: server.id,
        })
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
          if ssh_banner.nil? || ssh_banner.empty?
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
        require "base64"
        require "openssl"
        private_key = OpenSSL::PKey::RSA.new(key)
        encrypted_password = Base64.decode64(encoded_password)
        password = private_key.private_decrypt(encrypted_password)
        password
      end

      def check_windows_password_available(server_id)
        sleep 10
        response = fetch_password_data(server_id)
        return false unless response.password_data

        true
      end

      def windows_password
        if not config_value(:connection_password)
          if config_value(:ssh_identity_file)
            if server
              print "\n#{ui.color("Waiting for Windows Admin password to be available: ", :magenta)}"
              print(".") until check_windows_password_available(server.id) { puts("done") }
              response = fetch_password_data(server.id)
              data = File.read(locate_config_value(:ssh_identity_file))
              config[:connection_password] = decrypt_admin_password(response.password_data, data)
            else
              print "\n#{ui.color("Fetchig instance details: \n", :magenta)}"
            end
          else
            ui.error("Cannot find SSH Identity file, required to fetch dynamically generated password")
            exit 1
          end
        else
          config_value(:connection_password)
        end
      end

      # Returns the name of node after evaluation of server id if %s is present.
      # Eg: "Test-%s" will return "Test-i-12345"  in case the instance id is i-12345
      def evaluate_node_name(node_name)
        node_name % server.id
      end

      # TODO: connection_protocol and connection_port used to choose winrm/ssh or 5985/22 based on the image chosen
      def connection_port
        port = config_value(:connection_port, knife_key_for_protocol(connection_protocol, :port))
        return port if port

        assign_default_port
      end

      # Set default port 5986 if winrm_ssl return true otherwise set it to 5985
      # Set default port 22 for ssh protocol
      # @return [Integer]
      def assign_default_port
        if winrm?
          config_value(:winrm_ssl) ? 5986 : 5985
        else
          22
        end
      end

      # url values override CLI flags, if you provide both
      # we'll use the one that you gave in the URL.
      def connection_protocol
        return @connection_protocol if @connection_protocol

        default_protocol = is_image_windows? ? "winrm" : "ssh"

        from_url = host_descriptor =~ %r{^(.*)://} ? $1 : nil
        from_cli = config[:connection_protocol]
        from_knife = Chef::Config[:knife][:connection_protocol]
        @connection_protocol = from_url || from_cli || from_knife || default_protocol
      end

      def connection_user
        @connection_user ||= config_value(:connection_user, knife_key_for_protocol(connection_protocol, :user))
      end

      def server_name
        return nil unless server

        server.public_dns_name || server.private_dns_name || server.private_ip_address
      end

      alias host_descriptor server_name

      # If we don't specify a security group or security group id, Fog will
      # pick the appropriate default one. In case of a VPC we don't know the
      # default security group id at this point unless we look it up, hence
      # 'default' is printed if no id was specified.
      def printed_security_groups
        if server.groups
          server.groups.join(", ")
        else
          "default"
        end
      end

      def printed_security_group_ids
        if server.security_group_ids
          server.security_group_ids.join(", ")
        else
          "default"
        end
      end

      def hashed_volume_tags
        hvt = {}
        volume_tags = config_value(:volume_tags)
        volume_tags.map { |t| key, val = t.split("="); hvt[key] = val } unless volume_tags.nil?

        hvt
      end

      def printed_volume_tags
        hashed_volume_tags.map { |tag, val| "#{tag}: #{val}" }.join(", ")
      end

      def hashed_tags
        ht = {}
        parse_aws_tags.map { |t| key, val = t.split("="); ht[key] = val } unless parse_aws_tags.nil?

        # Always set the Name tag
        unless ht.keys.include? "Name"
          if config_value(:chef_node_name)
            ht["Name"] = evaluate_node_name(config_value(:chef_node_name))
          else
            ht["Name"] = server.id
          end
        end

        ht
      end

      def printed_aws_tags
        hashed_tags.map { |tag, val| "#{tag}: #{val}" }.join(", ")
      end

      def printed_t2_t3_unlimited
        if config[:cpu_credits] == "unlimited"
          "Enabled"
        else
          "Disabled"
        end
      end

      def reload_server_data_required?
        !!config[:associate_eip] || !!config[:classic_link_vpc_id] || !!config[:network_interfaces]
      end
    end
  end
end
