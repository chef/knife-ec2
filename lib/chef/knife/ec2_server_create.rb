#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
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
            Chef::Log.debug("Create server params - server_def = #{@create_options[:server_def]}")
            super
        end

        # Setup the floating ip after server creation.
        def after_exec_command
          msg_pair("Flavor", server.flavor_id)
          msg_pair("Image", server.image_id)
          msg_pair("Public IP Address", server.public_ip_address) if server.public_ip_address
          msg_pair("Private IP Address", server.private_ip_address) if server.private_ip_address
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
      end
    end
  end
end
