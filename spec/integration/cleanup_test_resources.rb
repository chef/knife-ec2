# Copyright: Copyright (c) 2013 Opscode, Inc.
# License: Apache License, Version 2.0
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

require 'mixlib/shellout'

module CleanupTestResources
  def self.validate_params
    unset_env_var = []

    # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are mandatory params to create Fog's connection object.
    %w(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY EC2_SSH_KEY_ID).each do |ec2_env_var|
      if ENV[ec2_env_var].nil?
        unset_env_var << ec2_env_var
      end
    end

    err_msg = "\nPlease set #{unset_env_var.join(', ')} environment"
    err_msg = err_msg + ( unset_env_var.length > 1 ? " variables " : " variable " ) + "to cleanup test resources."
    if ! unset_env_var.empty?
      puts err_msg
      exit 1
    end
  end

  # Use Mixlib::ShellOut to run knife ec2 commands.
  def self.run(command_line)
    shell_out = Mixlib::ShellOut.new("#{command_line}") 
    shell_out.timeout = 3000
    shell_out.run_command
    return shell_out
  end

  # Use knife ec2 to delete servers.
  def self.cleanup_resources

    delete_resources = []

    # Ec2 credentials use during knife ec2 command run.
    ec2_creds = "--aws-access-key-id '#{ENV['AWS_ACCESS_KEY_ID']}' --aws-secret-access-key '#{ENV['AWS_SECRET_ACCESS_KEY']}' "

    # List all servers in ec2 using knife ec2 server list command.
    list_command = "knife ec2 server list #{ec2_creds}"
    list_output = run(list_command)

    # Check command exitstatus. Non zero exitstatus indicates command execution fails.
    if list_output.exitstatus != 0
      puts "Cleanup Test Resources failed. Please check AWS aws-access-key-id and aws-secret-access-key are correct. Error: #{list_output.stderr}."
      exit list_output.exitstatus
    else
      servers = list_output.stdout
    end

    # We use "ec2-integration-test-<platform>-<randomNumber>" pattern for server name during integration tests run. So use "ec2-integration-test-" pattern to find out servers created during integration tests run.
    servers.each_line do |line|
      if (line.include?("ec2-integration-test-") && line.include?("running")) || (line.include?("ec2-") && line.include?("#{ENV['EC2_SSH_KEY_ID']}") && line.include?("running"))
        # Extract and add instance id of server to delete_resources list.
        delete_resources << {"id" => line.split(" ").first, "name" => line.split(" ")[1]}
      end
    end

    # Delete servers
    delete_resources.each do |resource|
      delete_command = "knife ec2 server delete #{resource['id']} #{ec2_creds} --yes"
      delete_output = run(delete_command)

      # check command exitstatus. Non zero exitstatus indicates command execution fails.
      if delete_output.exitstatus != 0
        puts "Unable to delete server #{resource['name']}: #{resource['id']}. Error: #{delete_output.stderr}."
      else
        puts "Deleted server #{resource['name']}: #{resource['id']}."
      end
    end
  end
end

CleanupTestResources.validate_params
CleanupTestResources.cleanup_resources
