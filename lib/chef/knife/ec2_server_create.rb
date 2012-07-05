#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

class Chef
  class Knife
    class Ec2ServerCreate < Knife

      include Knife::Ec2Base

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        require 'chef/knife/ssh'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 server create (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server (m1.small, m1.medium, etc)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f },
        :default => "m1.small"

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The AMI for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i }

      option :security_groups,
        :short => "-G X,Y,Z",
        :long => "--groups X,Y,Z",
        :description => "The security groups for this server",
        :default => ["default"],
        :proc => Proc.new { |groups| groups.split(',') }

      option :tags,
        :short => "-T T=V[,T=V,...]",
        :long => "--tags Tag=Value[,Tag=Value...]",
        :description => "The tags for this server",
        :proc => Proc.new { |tags| tags.split(',') }

      option :availability_zone,
        :short => "-Z ZONE",
        :long => "--availability-zone ZONE",
        :description => "The Availability Zone",
        :default => "us-east-1b",
        :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "The AWS SSH key id",
        :proc => Proc.new { |key| Chef::Config[:knife][:aws_ssh_key_id] = key }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_user] = key }

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
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

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

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :ebs_size,
        :long => "--ebs-size SIZE",
        :description => "The size of the EBS volume in GB, for EBS-backed instances"

      option :ebs_no_delete_on_term,
        :long => "--ebs-no-delete-on-term",
        :description => "Do not delete EBS volumn on instance termination"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :subnet_id,
        :short => "-s SUBNET-ID",
        :long => "--subnet SUBNET-ID",
        :description => "create node in this Virtual Private Cloud Subnet ID (implies VPC mode)",
        :default => false

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :aws_user_data,
        :long => "--user-data USER_DATA_FILE",
        :short => "-u USER_DATA_FILE",
        :description => "The EC2 User Data file to provision the instance with",
        :proc => Proc.new { |m| Chef::Config[:knife][:aws_user_data] = m },
        :default => nil

      def tcp_test_ssh(hostname)

        ssh_error_handler = Proc.new do |server|
          Chef::Log.debug("Failed to connect to #{hostname}")
        end

        session = Net::SSH::Multi.start()
        if config[:ssh_gateway]
          gw_host, gw_user = config[:ssh_gateway].split('@').reverse
          gw_host, gw_port = gw_host.split(':')
          gw_opts = gw_port ? { :port => gw_port } : {}
          session.via(gw_host, gw_user || config[:ssh_user], gw_opts)
        end

        hostspec = config[:ssh_user] + '@' + hostname + ':22'
        session_opts = {}
        session_opts[:keys] = File.expand_path(config[:identity_file]) if config[:identity_file]
        session_opts[:password] = config[:ssh_password] if config[:ssh_password]
        session_opts[:port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        if config[:no_host_key_verify]
          session_opts[:paranoid] = false
          session_opts[:user_known_hosts_file] = "/dev/null"
        end

        connected = nil
        begin
          session.use(hostspec, session_opts)
          session.open_channel do |ch|
            ch.request_pty
            ch.exec "ls" do |ch, success|
              raise ArgumentError, "Cannot connect" unless success
            end
          end
          connected = true
          session && session.close
          session.loop
        rescue
          connected = false
        end
        connected
      end

      def run
        $stdout.sync = true

        validate!

        config[:ssh_gateway] = locate_config_value 'ssh_gateway'
        config[:ssh_user] = locate_config_value 'ssh_user'
        config[:ssh_port] = locate_config_value 'ssh_port'
        config[:availability_zone] = locate_config_value 'availability_zone'
        config[:region] = locate_config_value 'region'
        config[:environment] = locate_config_value(:environment) || Chef::Config['environment']

        server = connection.servers.create(create_server_def)

        hashed_tags={}
        tags.map{ |t| key,val=t.split('='); hashed_tags[key]=val} unless tags.nil?

        # Always set the Name tag
        unless hashed_tags.keys.include? "Name"
          hashed_tags["Name"] = locate_config_value(:chef_node_name) || server.id
        end

        hashed_tags.each_pair do |key,val|
          connection.tags.create :key => key, :value => val, :resource_id => server.id
        end

        msg_pair("Instance ID", server.id)
        msg_pair("Flavor", server.flavor_id)
        msg_pair("Image", server.image_id)
        msg_pair("Region", connection.instance_variable_get(:@region))
        msg_pair("Availability Zone", server.availability_zone)
        msg_pair("Security Groups", server.groups.join(", "))
        msg_pair("Tags", hashed_tags)
        msg_pair("SSH Key", server.key_name)

        print "\n#{ui.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        if vpc_mode?
          msg_pair("Subnet ID", server.subnet_id)
        else
          msg_pair("Public DNS Name", server.dns_name)
          msg_pair("Public IP Address", server.public_ip_address)
          msg_pair("Private DNS Name", server.private_dns_name)
        end
        msg_pair("Private IP Address", server.private_ip_address)

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        fqdn = vpc_mode? ? server.private_ip_address : server.dns_name

        print(".") until tcp_test_ssh(fqdn) {
          sleep @initial_sleep_delay ||= (vpc_mode? ? 40 : 10)
          puts("done")
        }

        bootstrap_for_node(server,fqdn).run

        puts "\n"
        msg_pair("Instance ID", server.id)
        msg_pair("Flavor", server.flavor_id)
        msg_pair("Image", server.image_id)
        msg_pair("Region", connection.instance_variable_get(:@region))
        msg_pair("Availability Zone", server.availability_zone)
        msg_pair("Security Groups", server.groups.join(", "))
        msg_pair("Tags", hashed_tags)
        msg_pair("SSH Key", server.key_name)
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
        if vpc_mode?
          msg_pair("Subnet ID", server.subnet_id)
        else
          msg_pair("Public DNS Name", server.dns_name)
          msg_pair("Public IP Address", server.public_ip_address)
          msg_pair("Private DNS Name", server.private_dns_name)
        end
        msg_pair("Private IP Address", server.private_ip_address)
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", config[:run_list].join(', '))
      end

      def bootstrap_for_node(server,fqdn)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [fqdn]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway] if config[:ssh_gateway]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        # may be needed for vpc_mode
        bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
        bootstrap
      end

      def vpc_mode?
        # Amazon Virtual Private Cloud requires a subnet_id. If
        # present, do a few things differently
        !!config[:subnet_id]
      end

      def ami
        @ami ||= connection.images.get(locate_config_value(:image))
      end

      def validate!

        super([:image, :aws_ssh_key_id, :aws_access_key_id, :aws_secret_access_key])

        if ami.nil?
          ui.error("You have not provided a valid image (AMI) value.  Please note the short option for this value recently changed from '-i' to '-I'.")
          exit 1
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

      def create_server_def
        server_def = {
          :image_id => locate_config_value(:image),
          :groups => config[:security_groups],
          :flavor_id => locate_config_value(:flavor),
          :key_name => Chef::Config[:knife][:aws_ssh_key_id],
          :availability_zone => locate_config_value(:availability_zone)
        }
        server_def[:subnet_id] = config[:subnet_id] if config[:subnet_id]

        if Chef::Config[:knife][:aws_user_data]
          begin
            server_def.merge!(:user_data => File.read(Chef::Config[:knife][:aws_user_data]))
          rescue
            ui.warn("Cannot read #{Chef::Config[:knife][:aws_user_data]}: #{$!.inspect}. Ignoring option.")
          end
        end

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
          server_def[:block_device_mapping] =
            [{
               'DeviceName' => ami_map["deviceName"],
               'Ebs.VolumeSize' => ebs_size,
               'Ebs.DeleteOnTermination' => delete_term
             }]
        end

        server_def
      end
    end
  end
end
