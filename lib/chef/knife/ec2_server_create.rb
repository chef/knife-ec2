#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'chef/knife/cloud/server/create_command'
require 'chef/knife/ec2_helpers'
require 'chef/knife/cloud/ec2_server_create_options'
require 'chef/knife/cloud/ec2_service'
require 'chef/knife/cloud/ec2_service_options'
require 'chef/knife/cloud/exceptions'

class Chef
  class Knife
    class Cloud
      class Ec2ServerCreate < ServerCreateCommand
        include Ec2Helpers
        include Ec2ServerCreateOptions
        include Ec2ServiceOptions

        banner "knife ec2 server create (options)"

        def before_exec_command
            # setup the create options
            @create_options = {
              :server_def => {
                #servers require a name, knife-cloud generates the chef_node_name
                :tags => {'Name' => config[:chef_node_name]},
                :image_id => locate_config_value(:image),
                :flavor_id => locate_config_value(:flavor),
                :groups => locate_config_value(:ec2_security_groups),
                :key_name => locate_config_value(:ec2_ssh_key_id)
              },
              :server_create_timeout => locate_config_value(:server_create_timeout)
            }

            if vpc_mode?
              @create_options[:server_def][:subnet_id] = locate_config_value(:subnet_id)
              @create_options[:server_def][:private_ip_address] = locate_config_value(:private_ip_address)
              @create_options[:server_def][:tenancy] = "dedicated" if locate_config_value(:dedicated_instance)
              @create_options[:server_def][:associate_public_ip] = locate_config_value(:associate_public_ip) if config[:associate_public_ip]
            end  

            @create_options[:server_def][:placement_group] = locate_config_value(:placement_group)
            @create_options[:server_def][:iam_instance_profile_name] = locate_config_value(:iam_instance_profile)

            if Chef::Config[:knife][:ec2_user_data]
              begin
                @create_options[:server_def].merge!(:user_data => File.read(Chef::Config[:knife][:ec2_user_data]))
              rescue
                ui.warn("Cannot read #{Chef::Config[:knife][:ec2_user_data]}: #{$!.inspect}. Ignoring option.")
              end
            end

            @create_options[:server_def][:ebs_optimized] =  config[:ebs_optimized] ? "true" : "false"

            Chef::Log.debug("Create server params - server_def = #{@create_options[:server_def]}")
            super
        end

        # Setup the floating ip after server creation.
        def after_exec_command
          msg_pair("Flavor", server.flavor_id)
          msg_pair("Image", server.image_id)
          msg_pair("Availability Zone", server.availability_zone) if server.availability_zone
          msg_pair("Region", service.connection.instance_variable_get(:@region)) 
          msg_pair("Public IP Address", server.public_ip_address) if server.public_ip_address
          msg_pair("Private IP Address", server.private_ip_address) if server.private_ip_address

          # If we don't specify a security group or security group id, Fog will
          # pick the appropriate default one. In case of a VPC we don't know the
          # default security group id at this point unless we look it up, hence
          # 'default' is printed if no id was specified.
          printed_security_groups = "default"
          printed_security_groups = server.groups.join(", ") if server.groups
          msg_pair("Security Groups", printed_security_groups) unless vpc_mode? or (server.groups.nil? and server.security_group_ids)

          printed_security_group_ids = "default"
          printed_security_group_ids = server.security_group_ids.join(", ") if server.security_group_ids
          msg_pair("Security Group Ids", printed_security_group_ids) if vpc_mode? or server.security_group_ids
          msg_pair("IAM Profile", locate_config_value(:iam_instance_profile))
          msg_pair("Public DNS Name", server.dns_name)
          if vpc_mode?
            msg_pair("Subnet ID", server.subnet_id)
            msg_pair("Tenancy", server.tenancy)
          else
            msg_pair("Private DNS Name", server.private_dns_name)
          end
          msg_pair("Placement Group", server.placement_group) unless server.placement_group.nil?
          msg_pair("Root Device Type", server.root_device_type)

          if server.root_device_type == "ebs"
            device_map = server.block_device_mapping.first
            msg_pair("Root Volume ID", device_map['volumeId'])
            msg_pair("Root Device Name", device_map['deviceName'])
            msg_pair("Root Device Delete on Terminate", device_map['deleteOnTermination'])

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
            msg_pair("EBS is Optimized", server.ebs_optimized.to_s)
          end
          super
        end

        def before_bootstrap
          super
          # Which IP address to bootstrap
          bootstrap_ip_address = server.public_ip_address if server.public_ip_address
          bootstrap_ip_address = server.private_ip_address if config[:private_network]
          Chef::Log.debug("Bootstrap IP Address: #{bootstrap_ip_address}")
          if bootstrap_ip_address.nil?
            error_message = "No IP address available for bootstrapping."
            ui.error(error_message)
            raise CloudExceptions::BootstrapError, error_message
          end
          config[:bootstrap_ip_address] = bootstrap_ip_address
        end

        def validate_params!
          super
          errors = []
          
          errors << "You must provide SSH Key." if locate_config_value(:bootstrap_protocol) == 'ssh' && !locate_config_value(:identity_file).nil? && locate_config_value(:ec2_ssh_key_id).nil?
            
          errors << "You must provide --image-os-type option [windows/linux]" if ! (%w(windows linux).include?(locate_config_value(:image_os_type)))
          error_message = ""
          raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
        end

        def vpc_mode?
          # Amazon Virtual Private Cloud requires a subnet_id. If
          # present, do a few things differently
          !!locate_config_value(:subnet_id)
        end

        def ami
          @ami ||= service.connection.images.get(locate_config_value(:image))
        end
      end
    end
  end
end
