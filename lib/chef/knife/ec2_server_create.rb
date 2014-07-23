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
        include Ec2ServiceOptions
        include Ec2ServerCreateOptions

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
                :availability_zone => locate_config_value(:availability_zone),
                :placement_group => locate_config_value(:placement_group),
                :iam_instance_profile_name => locate_config_value(:iam_instance_profile)
              },
              :server_create_timeout => locate_config_value(:server_create_timeout)
            }

            load_vpc_create_options if vpc_mode?

            # Load user data scripts in @create_options[:server_def][:user_data]
            load_user_data

            # Load options related to EBS
            load_ebs_create_options

            (config[:ephemeral] || []).each_with_index do |device_name, i|
              @create_options[:server_def][:block_device_mapping] = (@create_options[:server_def][:block_device_mapping] || []) << {'VirtualName' => "ephemeral#{i}", 'DeviceName' => device_name}
            end

            Chef::Log.debug("Create server params - server_def = #{@create_options[:server_def]}")
            super
        end

        # Override to parse error messages
        def execute_command
          begin
            super
          rescue CloudExceptions::ServerCreateError => e
            ebs_optimized_fog_msg = "ebs-optimized instances are not supported for your requested configuration"
            placement_grp_fog_msg = "placement groups may not be used with instances of type"
            err_msg = e.message.downcase

            flavor = locate_config_value(:flavor)
            error_message = "Please check if " + (flavor.nil? ? "default flavor is supported for " : "flavor #{flavor} is supported for ")

            if err_msg.include?(ebs_optimized_fog_msg)
              error_message += "EBS-optimized instances."
              ui.error(error_message)
            elsif err_msg.include?(placement_grp_fog_msg)
              error_message += "Placement groups."
              ui.error(error_message)
            end

            raise e
          end
        end

        # Setup the floating ip after server creation.
        def after_exec_command
          # In case server is not 'ready?', so retry a couple times if needed.
          tries = 6
          begin
            create_tags
            associate_eip
          rescue Fog::Compute::AWS::NotFound, Fog::Errors::Error => e
            raise if (tries -= 1) <= 0
            ui.warn("server not ready, retrying tag application (retries left: #{tries})")
            sleep 5
            retry
          end

          # Any warnings? Display.
          if server.root_device_type == "ebs" and config[:ebs_size]
            if ami.block_device_mapping.first['volumeSize'].to_i < config[:ebs_size].to_i
              volume_too_large_warning = "#{config[:ebs_size]}GB " +
                          "EBS volume size is larger than size set in AMI of " +
                          "#{ami.block_device_mapping.first['volumeSize']}GB.\n" +
                          "Use file system tools to make use of the increased volume size."
              ui.warn(volume_too_large_warning)
            end
          end

          setup_summary_colinfo
          service.server_summary(server, @columns_with_info)
          super
        end

        def before_bootstrap
          super
          bootstrap_ip_address ||= if config[:server_connect_attribute]
                                      server.send(config[:server_connect_attribute])
                                  else
                                    if vpc_mode? && !config[:associate_public_ip]
                                      server.private_ip_address
                                    else
                                      server.dns_name
                                    end
                                  end
          # Which IP address to bootstrap
          Chef::Log.debug("Bootstrap IP Address: #{bootstrap_ip_address}")
          if bootstrap_ip_address.nil?
            error_message = "No IP address available for bootstrapping."
            ui.error(error_message)
            raise CloudExceptions::BootstrapError, error_message
          end
          config[:bootstrap_ip_address] = bootstrap_ip_address

          # Modify global configuration state to ensure hint gets set by
          # knife-bootstrap.
          Chef::Config[:knife][:hints] ||= {}
          Chef::Config[:knife][:hints]["ec2"] ||= {}
        end

        def validate_params!
          super

          validate_tags

          errors = []

          errors << "You must provide SSH Key." if locate_config_value(:bootstrap_protocol) == 'ssh' && !locate_config_value(:identity_file).nil? && locate_config_value(:ec2_ssh_key_id).nil?

          errors << "You must provide --image-os-type option [windows/linux]" if ! (%w(windows linux).include?(locate_config_value(:image_os_type)))

          errors << "You are using a VPC, security groups specified with '--ec2-groups' are not allowed, specify one or more security group ids with '--security-group-ids' instead." if vpc_mode? and !!config[:ec2_security_groups]

          errors << "You can only specify a private IP address if you are using VPC." if !vpc_mode? and !!config[:private_ip_address]

          errors << "You can only specify a Dedicated Instance if you are using VPC." if config[:dedicated_instance] and !vpc_mode?

          errors << "--associate-public-ip option only applies to VPC instances, and you have not specified a subnet id." if !vpc_mode? and config[:associate_public_ip]

          errors << "--provisioned-iops option is only supported for volume type of 'io1'" if locate_config_value(:ebs_provisioned_iops) and locate_config_value(:ebs_volume_type) != 'io1'

          errors << "--provisioned-iops option is required when using volume type of 'io1'" if locate_config_value(:ebs_volume_type) == 'io1' and locate_config_value(:ebs_provisioned_iops).nil?

          errors << "--ebs-volume-type must be 'standard' or 'io1' or 'gp2'"  if locate_config_value(:ebs_volume_type) and ! %w(gp2 io1 standard).include?(locate_config_value(:ebs_volume_type))

          error_message = ""
          raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
        end

        def validate_ami
          errors = []
          errors << "You have not provided a valid image (AMI) value." if ami.nil?
          error_message = ""
          raise CloudExceptions::ValidationError, error_message if errors.each{|e| ui.error(e); error_message = "#{error_message} #{e}."}.any?
        end

        def validate_elastic_ip_availability
          if config[:associate_eip]
            eips = service.connection.addresses.collect{|addr| addr if addr.domain == eip_scope}.compact

            unless eips.detect{|addr| addr.public_ip == config[:associate_eip] && addr.server_id == nil}
              error_message = "Requested elastic IP is not available.[#{config[:associate_eip]}]"
              ui.error(error_message)
              raise CloudExceptions::ValidationError, error_message
            end
          end
        end

        def validate_ebs
          unless config[:ebs_size].nil?
            if config[:ebs_size].to_i < ami.block_device_mapping.first["volumeSize"]
              error_message = "EBS-size is smaller than snapshot '#{ami.block_device_mapping.first["snapshotId"]}', expect size >= #{ami.block_device_mapping.first['volumeSize']}"
              ui.error(error_message)
              raise CloudExceptions::ValidationError, error_message
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

        def validate_tags
         tags = locate_config_value(:tags)
          if !tags.nil? and tags.length != tags.to_s.count('=')
            error_message = "Tags should be entered in a key = value pair"
            ui.error(error_message)
            raise CloudExceptions::ValidationError, error_message
          end
        end

        def eip_scope
          vpc_mode? ? "vpc" : "standard"
        end

        def create_tags
          hashed_tags.each_pair do |key, val|
            service.connection.tags.create :key => key, :value => val, :resource_id => server.id
          end
        end

        def post_connection_validations
          validate_ami
          validate_elastic_ip_availability
          validate_ebs
        end

        def associate_eip
          if config[:associate_eip]
            requested_elastic_ip = config[:associate_eip]

            # For VPC EIP assignment we need the allocation ID so fetch full EIP details
            elastic_ip = service.connection.addresses.detect{|addr| addr if addr.public_ip == requested_elastic_ip}

            if elastic_ip
             service.connection.associate_address(server.id, elastic_ip.public_ip, nil, elastic_ip.allocation_id)
              server.wait_for { public_ip_address == elastic_ip.public_ip }
            end
          end
        end

        def set_image_os_type
          config[:image_os_type] = (ami.platform == 'windows') ?  'windows' :  'linux'
        end

        def windows_password
          unless locate_config_value(:winrm_password)
            if locate_config_value(:identity_file)
              print "\n#{ui.color("Waiting for Windows Admin password to be available", :magenta)}"
              print(".") until check_windows_password_available(server.id) {
                sleep 1000 #typically is available after 30 mins
                puts("done")
              }
              response = service.connection.get_password_data(server.id)
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

        def check_windows_password_available(server_id)
          response = service.connection.get_password_data(server_id)
          response.body["passwordData"] ? response.body["passwordData"] : false
        end

        def load_vpc_create_options
          @create_options[:server_def][:subnet_id] = locate_config_value(:subnet_id)
          @create_options[:server_def][:private_ip_address] = locate_config_value(:private_ip_address)
          @create_options[:server_def][:tenancy] = "dedicated" if locate_config_value(:dedicated_instance)
          @create_options[:server_def][:associate_public_ip] = locate_config_value(:associate_public_ip) if config[:associate_public_ip]
        end

        def load_ebs_create_options
          if ami.root_device_type == "ebs"
            ami_map = ami.block_device_mapping.first
            ebs_size = begin
                         config[:ebs_size] ? Integer(config[:ebs_size]).to_s : ami_map["volumeSize"].to_s
                       rescue ArgumentError
                         error_message = "--ebs-size must be an integer"
                         msg opt_parser
                         ui.errors(error_message)
                         raise CloudExceptions::ValidationError, error_message
                       end
            delete_term = config[:ebs_no_delete_on_term] ? "false" : ami_map["deleteOnTermination"]

            iops_rate = begin
                        if config[:ebs_provisioned_iops]
                          Integer(config[:ebs_provisioned_iops]).to_s
                        else
                          ami_map["iops"].to_s
                        end
                      rescue ArgumentError
                        error_message = "--provisioned-iops must be an integer"
                        msg opt_parser
                        ui.errors(error_message)
                        raise CloudExceptions::ValidationError, error_message
                      end

            @create_options[:server_def][:block_device_mapping] =
              [{
                 'DeviceName' => ami_map["deviceName"],
                 'Ebs.VolumeSize' => ebs_size,
                 'Ebs.DeleteOnTermination' => delete_term,
                 'Ebs.VolumeType' => config[:ebs_volume_type]
               }]
            @create_options[:server_def][:block_device_mapping].first['Ebs.Iops'] = iops_rate unless iops_rate.empty?
          end
          @create_options[:server_def][:ebs_optimized] = config[:ebs_optimized] ? "true" : "false"
        end

        def load_user_data_for_win
          # we cannot have multiple <powershell> tags in the user-data. all PS scripts should be
          # enclosed withing single <powershell>..</powershell> tag.
          @create_options[:server_def].merge!(:user_data => "<powershell>")
          if(locate_config_value(:bootstrap_protocol) == "winrm")
            @create_options[:server_def][:user_data] << "$computer = [ADSI]\"WinNT://$env:computername,computer\"\n$username = \"#{locate_config_value(:winrm_user)}\"\n$splitusername=$username.split(\"\\\\\")\nif($splitusername[1] -eq $null) { $username = $splitusername[0] }\nelse { $username = $splitusername[1] }\n$newuser = $computer.Create(\"user\", $username)\n $newuser.Path = $newuser.Path -replace(\".\\\\\", \"\")\n $newuser.SetPassword(\"#{windows_password}\")\n$newuser.SetInfo()\n $localadmin = ([adsi](\"WinNT://./Administrators,group\"))\n $localadmin.PSBase.Invoke(\"Add\",$newuser.PSBase.Path)\n " if locate_config_value(:winrm_user).downcase != "administrator"
          else
            @create_options[:server_def][:user_data] << "$computer = [ADSI]\"WinNT://$env:computername,computer\"\n$newuser = $computer.Create(\"user\", \"#{locate_config_value(:ssh_user)}\")\n $newuser.SetPassword(\"#{locate_config_value(:ssh_password)}\")\n$newuser.SetInfo()\n $localadmin = ([adsi](\"WinNT://./Administrators,group\"))\n $localadmin.PSBase.Invoke(\"Add\",$newuser.PSBase.Path)\n " if locate_config_value(:ssh_user).downcase != "administrator"
          end
          if Chef::Config[:knife][:aws_user_data]
            begin
              user_data_file = File.read(Chef::Config[:knife][:aws_user_data]).gsub("<powershell>", "").gsub("</powershell>", "")
              if(user_data_file.include? "<script>")
                @create_options[:server_def][:user_data] << "</powershell>"
                @create_options[:server_def][:user_data ] << user_data_file
              else
                @create_options[:server_def][:user_data ] << user_data_file
                @create_options[:server_def][:user_data] << "</powershell>"
              end
            rescue
              ui.warn("Cannot read #{Chef::Config[:knife][:aws_user_data]}: #{$!.inspect}. Ignoring option.")
            end
          else
            @create_options[:server_def][:user_data] << "</powershell>"
          end

          # in case there is no PS script, we dont send empty <powershell> script to ec2 user-data
          @create_options[:server_def][:user_data].gsub("<powershell></powershell>", "")
        end

        def load_user_data
          if service.is_image_windows?(locate_config_value(:image))
            load_user_data_for_win
            Chef::Log.debug @create_options[:server_def][:user_data]
          else
            if Chef::Config[:knife][:aws_user_data]
              begin
                @create_options[:server_def].merge!(:user_data => File.read(Chef::Config[:knife][:aws_user_data]))
              rescue
                ui.warn("Cannot read #{Chef::Config[:knife][:aws_user_data]}: #{$!.inspect}. Ignoring option.")
              end
            end
          end
        end

        def hashed_tags
          @hashed_tags ||= begin
            tags = locate_config_value(:tags)

            hashed_tags={}
            tags.map{ |t| key, val = t.split('='); hashed_tags[key] = val } unless tags.nil?

            # Always set the Name tag
            unless hashed_tags.keys.include? "Name"
              hashed_tags["Name"] = locate_config_value(:chef_node_name) || @server.id
            end
            hashed_tags
          end
        end

        # setup the @columns_with_info to display the server summary.
        def setup_summary_colinfo
          @columns_with_info = [{:label => 'Instance Name', :value => service.get_server_name(server)},
                                {:label => 'Instance ID', :key => 'id'},
                                {:label => 'Flavor', :key => 'flavor_id'},
                                {:label => 'Image', :key => 'image_id'},
                                {:label => 'Availability Zone', :key => 'availability_zone'},
                                {:label => 'Public IP Address', :key => 'public_ip_address'},
                                {:label => 'Private IP Address', :key => 'private_ip_address'},
                                {:label => 'IAM Profile', :key => 'iam_instance_profile', :value_callback => method(:iam_name_from_profile)},
                                {:label => 'Placement Group', :key => 'placement_group'},
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

          if vpc_mode?
            @columns_with_info << {:label => 'Subnet ID', :key => 'subnet_id'}
            @columns_with_info << {:label => 'Tenancy', :key => 'tenancy'}
            @columns_with_info << {:label => 'Public DNS Name', :key => 'dns_name'} if config[:associate_public_ip]
          else
            @columns_with_info << {:label => 'Public DNS Name', :key => 'dns_name'}
            @columns_with_info << {:label => 'Private DNS Name', :key => 'private_dns_name'}
          end

          if server.root_device_type == "ebs"
            device_map = server.block_device_mapping.first
            volume = server.volumes.first
            @columns_with_info << {:label => "Root Volume ID", :value => device_map['volumeId']}
            @columns_with_info << {:label => "Root Device Name", :value => device_map['deviceName']}
            @columns_with_info << {:label => "Root Device Delete on Terminate", :value => device_map['deleteOnTermination'].to_s}
            @columns_with_info << {:label => "Standard or Provisioned IOPS", :value => volume.type}
            @columns_with_info << {:label => "IOPS rate", :value => volume.iops.to_s}
          end

          @columns_with_info << {:label => "EBS is Optimized", :key => 'ebs_optimized'} if config[:ebs_optimized]
        end
      end
    end
  end
end
