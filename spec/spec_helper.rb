# Copyright: Copyright (c) 2014 Opscode, Inc.
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

# Author:: Siddheshwar More (<siddheshwar.more@clogeny.com>)

$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/node'
require 'fog'
require 'chef/knife/ec2_server_create'
require 'chef/knife/bootstrap_windows_ssh'
require 'resource_spec_helper'
require 'test/knife-utils/test_bed'
require "securerandom"
require 'server_command_common_spec_helper'

def find_instance_id(instance_name, file)
  file.lines.each do |line|
    if line.include?("#{instance_name}")
      return "#{line}".split(" ")[2].strip
    end
  end
end

def delete_instance_cmd(stdout)
  "knife ec2 server delete " + find_instance_id("Instance ID", stdout) +
  append_ec2_creds + " --yes"
end

def is_config_present
  if ! ENV['RUN_INTEGRATION_TESTS']
    puts("\nPlease set RUN_INTEGRATION_TESTS environment variable to run integration tests")
    return false
  end

  unset_env_var = []
  unset_config_options = []
  is_config = true
  config_file_exist = File.exist?(File.expand_path("../integration/config/environment.yml", __FILE__))
  ec2_config = YAML.load(File.read(File.expand_path("../integration/config/environment.yml", __FILE__))) if config_file_exist
  %w(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY).each do |aws_env_var|
      if ENV[aws_env_var].nil?
        unset_env_var <<  aws_env_var
        is_config = false
      end
    end

  err_msg = "\nPlease set #{unset_env_var.join(', ')} environment"
  err_msg = err_msg + ( unset_env_var.length > 1 ? " variables " : " variable " ) + "for integration tests."
  puts err_msg unless unset_env_var.empty?
  
  %w(EC2_SSH_USER EC2_GROUPS EC2_SSH_KEY_ID EC2_PRI_KEY EC2_INVALID_FLAVOR EC2_LINUX_IMAGE EC2_WINDOWS_IMAGE EC2_WINDOWS_SSH_IMAGE EC2_WINDOWS_SSH_USER EC2_WINDOWS_SSH_PASSWORD PLACEMENT_GROUP SUBNET_ID SECURITY_GROUP_IDS).each do |ec2_config_opt|
    option_value = ENV[ec2_config_opt] || (ec2_config[ec2_config_opt] if ec2_config)
    if option_value.nil?
      unset_config_options << ec2_config_opt
      is_config = false
    end
  end

  config_err_msg = "\nPlease set #{unset_config_options.join(', ')} config"
  config_err_msg = config_err_msg + ( unset_config_options.length > 1 ? " options in ../spec/integration/config/environment.yml or as environment variables" : " option in ../spec/integration/config/environment.yml or as environment variable" ) + " for integration tests."
  puts config_err_msg unless unset_config_options.empty?
  
  is_config
end

def get_gem_file_name
  "knife-ec2-" + Knife::Ec2::VERSION + ".gem"
end

def create_node_name(name)
  @name_node  = (name == "linux") ? "ec2-integration-test-linux-#{SecureRandom.hex(4)}" :  "ec2-integration-test-win-#{SecureRandom.hex(4)}"
end


def get_fog_connection
  auth_params = { :provider => 'AWS', :aws_access_key_id => "#{ENV['AWS_ACCESS_KEY_ID']}",
                     :aws_secret_access_key => "#{ENV['AWS_SECRET_ACCESS_KEY']}" }
    
  begin
    fog_connection = Fog::Compute.new(auth_params)  
  rescue Exception => e
    puts "Connection failure, please check your authentication config. #{e.message}"
    exit 1
  end
  fog_connection
end

def check_and_delete_preserved_ebs_volume(cmd_output)
  ebs_volume_id = ""

  # get ebs_volume_id from command output
  cmd_output.lines.each do |line|
    if line.include?("Root Volume ID")
      ebs_volume_id = "#{line}".split(" ")[3].strip
    end
  end

  # Delete instance
  run(delete_instance_cmd(cmd_output))
  
  # create fog Connection to check preseved ebs volume
  fog_connection = get_fog_connection

  # Check for ebs volume
  fog_connection.volumes.get(ebs_volume_id).should_not be_nil

  tries = 6
  # Cleanup preseved ebs volume
  begin
    fog_connection.volumes.get(ebs_volume_id).destroy  
  rescue Exception => e
    # wait for detach ebs volume
    puts "Preseved ebs volume: '#{ebs_volume_id}' not deleted. Please use AWS Console to delete it.Error: #{e.message}" if (tries -= 1) <= 0
    sleep 30
    retry
  end
end

def init_ec2_test
  init_test

  begin
    data_to_write = File.read(File.expand_path("../integration/config/incorrect_ec2.pem", __FILE__))
    File.open("#{temp_dir}/incorrect_ec2.pem", 'w') {|f| f.write(data_to_write)}
  rescue
    puts "Error while creating file - incorrect_ec2.pem"
  end

  config_file_exist = File.exist?(File.expand_path("../integration/config/environment.yml", __FILE__))
  ec2_config = YAML.load(File.read(File.expand_path("../integration/config/environment.yml", __FILE__))) if config_file_exist

  %w(EC2_SSH_USER EC2_GROUPS EC2_SSH_KEY_ID EC2_PRI_KEY EC2_INVALID_FLAVOR EC2_LINUX_IMAGE EC2_WINDOWS_IMAGE EC2_WINDOWS_SSH_IMAGE EC2_WINDOWS_SSH_USER EC2_WINDOWS_SSH_PASSWORD PLACEMENT_GROUP SUBNET_ID SECURITY_GROUP_IDS).each do |ec2_config_opt|
    instance_variable_set("@#{ec2_config_opt.downcase}", (ec2_config[ec2_config_opt] if ec2_config) || ENV[ec2_config_opt])
  end

  begin
    data_to_write = @ec2_pri_key
    File.open("#{temp_dir}/ec2.pem", 'w') {|f| f.write(data_to_write)}
  rescue
    puts "Error while creating file - ec2.pem"
  end
end
