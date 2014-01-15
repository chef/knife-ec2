# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

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
            set_image_os_type
            # setup the create options
            @create_options = {
              :server_def => {
                #servers require a name, knife-cloud generates the chef_node_name
                :tags => {'Name' => config[:chef_node_name]},
                :image_id => locate_config_value(:image),
                :flavor_id => locate_config_value(:flavor),
                :groups => locate_config_value(:ec2_security_groups),
                :security_group_ids => locate_config_value(:security_group_ids),
                :key_name => locate_config_value(:ec2_ssh_key_id),
                :availability_zone => locate_config_value(:availability_zone)
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

            if Chef::Config[:knife][:aws_user_data]
              begin
                @create_options[:server_def].merge!(:user_data => File.read(Chef::Config[:knife][:aws_user_data]))
              rescue
                ui.warn("Cannot read #{Chef::Config[:knife][:aws_user_data]}: #{$!.inspect}. Ignoring option.")
              end
            end

            @create_options[:server_def][:ebs_optimized] = config[:ebs_optimized] ? "true" : "false"

            if ami.root_device_type == "ebs"
              ami_map = ami.block_device_mapping.first
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

              @create_options[:server_def][:block_device_mapping] =
                [{
                   'DeviceName' => ami_map["deviceName"],
                   'Ebs.VolumeSize' => ebs_size,
                   'Ebs.DeleteOnTermination' => delete_term
                 }]
            end

            (config[:ephemeral] || []).each_with_index do |device_name, i|
              @create_options[:server_def][:block_device_mapping] = (@create_options[:server_def][:block_device_mapping] || []) << {'VirtualName' => "ephemeral#{i}", 'DeviceName' => device_name}
            end

            Chef::Log.debug("Create server params - server_def = #{@create_options[:server_def]}")
            super
        end

        # Setup the floating ip after server creation.
        def after_exec_command
          hashed_tags={}
          tags.map{ |t| key, val=t.split('='); hashed_tags[key]=val} unless tags.nil?

          # Always set the Name tag
          unless hashed_tags.keys.include? "Name"
            hashed_tags["Name"] = locate_config_value(:chef_node_name) || @server.id
          end

          @columns_with_info = [{:label => 'Instance Name', :value => service.get_server_name(server)},
                                {:label => 'Instance ID', :key => 'id'},
                                {:label => 'Flavor', :key => 'flavor_id'},
                                {:label => 'Image', :key => 'image_id'}, 
                                {:label => 'Availability Zone', :key => 'availability_zone'},
                                {:label => 'Public IP Address', :key => 'public_ip_address'},
                                {:label => 'Private IP Address', :key => 'private_ip_address'},
                                {:label => 'IAM Profile', :key => 'iam_instance_profile'},
                                {:label => 'Placement Group', :key => 'placement_group'},
                                {:label => 'Public DNS Name', :key => 'dns_name'},
                                {:label => 'Root Device Type', :key => 'root_device_type'},
                                {:label => "Region", :value => service.connection.instance_variable_get(:@region)},
                                {:label => "Tags", :value => hashed_tags.map{ |tag, val| "#{tag}: #{val}" }.join(", ")},
                                {:label => "SSH Key", :key => 'key_name'} 
                               ]

          # If we don't specify a security group or security group id, Fog will
          # pick the appropriate default one. In case of a VPC we don't know the
          # default security group id at this point unless we look it up, hence
          # 'default' is printed if no id was specified.
          printed_security_groups = "default"
          printed_security_groups = server.groups.join(", ") if server.groups
          @columns_with_info << {:label => 'Security Groups', :value => printed_security_groups} unless vpc_mode? or (server.groups.nil? and server.security_group_ids)

          printed_security_group_ids = "default"
          printed_security_group_ids = server.security_group_ids.join(", ") if server.security_group_ids
          @columns_with_info << {:label => 'Security Group Ids', :value =>  printed_security_group_ids} if vpc_mode? or server.security_group_ids          

          begin
            create_tags(hashed_tags) unless hashed_tags.empty?
            associate_eip(elastic_ip) if config[:associate_eip]
          rescue Fog::Compute::AWS::NotFound, Fog::Errors::Error => e
            raise if (tries -= 1) <= 0
            ui.warn("server not ready, retrying tag application (retries left: #{tries})")
            sleep 5
            retry
          end

          if vpc_mode?
            @columns_with_info << {:label => 'Subnet ID', :key => 'subnet_id'}
            @columns_with_info << {:label => 'Tenancy', :key => 'tenancy'}
          else
            @columns_with_info << {:label => 'Private DNS Name', :key => 'private_dns_name'}
          end

          if server.root_device_type == "ebs"
            device_map = server.block_device_mapping.first
            @columns_with_info << {:label => "Root Volume ID", :value => device_map['volumeId']}
            @columns_with_info << {:label => "Root Device Name", :value => device_map['deviceName']}
            @columns_with_info << {:label => "Root Device Delete on Terminate", :value => device_map['deleteOnTermination'].to_s}

            if config[:ebs_size]
              if ami.block_device_mapping.first['volumeSize'].to_i < config[:ebs_size].to_i
                volume_too_large_warning = "#{config[:ebs_size]}GB " +
                            "EBS volume size is larger than size set in AMI of " +
                            "#{ami.block_device_mapping.first['volumeSize']}GB.\n" +
                            "Use file system tools to make use of the increased volume size."
                ui.warn(volume_too_large_warning)            
              end
            end
          end
          
          @columns_with_info << {:label => "EBS is Optimized", :key => 'ebs_optimized'} if config[:ebs_optimized]
          service.server_summary(server, @columns_with_info)
          super
        end

        def before_bootstrap
          super
          # Which IP address to bootstrap
          bootstrap_ip_address = server.public_ip_address if server.public_ip_address
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

          errors << "You are using a VPC, security groups specified with '-G' are not allowed, specify one or more security group ids with '-g' instead." if vpc_mode? and !!config[:security_groups]

          errors << "You can only specify a private IP address if you are using VPC." if !vpc_mode? and !!config[:private_ip_address]

          errors << "You can only specify a Dedicated Instance if you are using VPC." if config[:dedicated_instance] and !vpc_mode?

          errors << "--associate-public-ip option only applies to VPC instances, and you have not specified a subnet id." if !vpc_mode? and config[:associate_public_ip]
  
          error_message = ""
          raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
        end

        def validate_ami
          errors = []
          errors << "You have not provided a valid image (AMI) value.  Please note the short option for this value recently changed from '-i' to '-I'." if ami.nil?
          error_message = ""
          raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
        end

        def validate_elastic_ip_availability
          if config[:associate_eip]
            eips = service.connection.addresses.collect{|addr| addr if addr.domain == eip_scope}.compact

            unless eips.detect{|addr| addr.public_ip == config[:associate_eip] && addr.server_id == nil}
              errors << "Elastic IP requested is not available."
            end
          end
        end

        def vpc_mode?
          # Amazon Virtual Private Cloud requires a subnet_id. If
          # present, do a few things differently
          !!locate_config_value(:subnet_id)
        end

        def ami
          @ami ||= service.connection.images.get(locate_config_value(:image))
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
          vpc_mode? ? "vpc" : "standard"
        end

        def create_tags(hashed_tags)
          hashed_tags.each_pair do |key, val|
            service.connection.tags.create :key => key, :value => val, :resource_id => server.id
          end
        end

        def post_connection_validations
          validate_ami
          validate_elastic_ip_availability
        end

        def associate_eip(elastic_ip)
          service.connection.associate_address(server.id, elastic_ip.public_ip, nil, elastic_ip.allocation_id)
          server.wait_for { public_ip_address == elastic_ip.public_ip }
        end

        def set_image_os_type
          ami.platform == 'windows'? config[:image_os_type] = 'windows' : config[:image_os_type] = 'linux'
        end
      end
    end
  end
end