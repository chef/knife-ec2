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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def append_ec2_creds
  ec2_creds_cmd = " --aws-access-key-id #{ENV['AWS_ACCESS_KEY_ID']} --aws-secret-access-key #{ENV['AWS_SECRET_ACCESS_KEY']}"
  ec2_creds_cmd = ec2_creds_cmd + " -c #{temp_dir}/knife.rb"
  ec2_creds_cmd
end

def get_ssh_credentials(invalid_key_id = false)
  ssh_creds =  " --ssh-user #{@ec2_ssh_user}"
  ssh_creds += invalid_key_id ? " --ec2-ssh-key-id invalid_key_id" : " --ec2-ssh-key-id #{@ec2_ssh_key_id}"
end

def get_linux_create_options(invalid_key = false)
  ec2_linux_create_cmd = " -I #{@ec2_linux_image} --server-url http://localhost:8889 --yes --server-create-timeout 1800 --template-file " + get_linux_template_file_path

  ec2_linux_create_cmd +=  invalid_key ? " --identity-file #{temp_dir}/incorrect_ec2.pem" : " --identity-file #{temp_dir}/ec2.pem"
end

def get_winrm_credentials
  " --winrm-user #{ENV['EC2_WINRM_USER']}  --winrm-password #{ENV['EC2_WINRM_PASSWORD']}"
end

def get_windows_create_options(bootstrap_protocol = "winrm")
  ec2_win_create_cmd = " --template-file " + get_windows_msi_template_file_path +
  " --server-url http://localhost:8889" +
  " --yes --server-create-timeout 1800"
  if bootstrap_protocol == "winrm"
    ec2_win_create_cmd += " -I #{@ec2_windows_image} --bootstrap-protocol winrm" + " --user-data #{ENV['EC2_USER_DATA']}"
  else
    ec2_win_create_cmd += " -I #{@ec2_windows_ssh_image} --bootstrap-protocol ssh --ec2-ssh-key-id #{@ec2_ssh_key_id}" + " --ssh-user #{@ec2_windows_ssh_user} --ssh-password #{@ec2_windows_ssh_password}"
  end
  ec2_win_create_cmd
end

def get_ssh_credentials_for_windows_image
  " --ssh-user #{@ec2_windows_ssh_user}"+
  " --ssh-password #{@ec2_windows_ssh_password}"
end

describe 'knife ec2 integration test' , :if => is_config_present do
  include KnifeTestBed
  include RSpec::KnifeTestUtils

  before(:all) do
    expect(run('gem build knife-ec2.gemspec').exitstatus).to be(0)
    expect(run("gem install #{get_gem_file_name}").exitstatus).to be(0)
    init_ec2_test
  end

  after(:all) do
    run("gem uninstall knife-ec2 -v '#{Knife::Ec2::VERSION}'")
    cleanup_test_data
  end

  describe 'display help for command' do
    %w{flavor\ list server\ create server\ delete server\ list}.each do |command|
      context "when --help option used with #{command} command" do
        let(:command) { "knife ec2 #{command} --help" }

        run_cmd_check_stdout("--help")
      end
    end
  end

  describe 'display server list' do
    context 'when standard options specified' do
      let(:command) { "knife ec2 server list" + append_ec2_creds }

      run_cmd_check_status_and_output("succeed", "Instance ID")
    end

    context 'when --availability-zone option specified' do
      let(:command) { "knife ec2 server list" + append_ec2_creds + " --availability-zone"}

      run_cmd_check_status_and_output("succeed", "Instance ID")
    end

    context 'when --no-name option specified' do
      cmd_out = ""

      let(:command) { "knife ec2 server list" + append_ec2_creds + " --no-name"}

      after { cmd_out = cmd_output }

      run_cmd_check_status_and_output("succeed", "Instance ID")

      it { cmd_out.should_not include("Name") }
    end

    context 'when -t option specified' do
      let(:command) { "knife ec2 server list" + append_ec2_creds + " -t name"}

      run_cmd_check_status_and_output("succeed", "Instance ID")
    end
  end

  describe 'display flavor list' do
    context 'when standard options specified' do
      let(:command) { "knife ec2 flavor list" + append_ec2_creds }
      
      run_cmd_check_status_and_output("succeed", "ID")
    end
  end

  describe 'create and bootstrap Linux Server'  do
    before(:each) {rm_known_host}

    context 'when standard options specified' do
      cmd_out = ""
      
      before { create_node_name("linux") }

      after { cmd_out = "#{cmd_output}" }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} " +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }
      run_cmd_check_status_and_output("succeed", "#{@name_node}")

      context "delete server after create" do
        let(:command) { delete_instance_cmd(cmd_out) }
        run_cmd_check_status_and_output("succeed", "#{@name_node}")
      end
    end

    context 'when standard options and invalid ec2 security group specified' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups invalid-invalid-1212" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "FATAL: The security group 'invalid-invalid-1212' does not exist")
    end

    context 'when standard options and ebs-volume-type standard specified' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type standard " +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and ebs-volume-type gp2 specified' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type gp2 " +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and ebs-volume-type io1 specified with provisioned-iops' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type io1  --provisioned-iops 123" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and ebs-volume-type io1 specified without provisioned-iops' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type io1 " +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: --provisioned-iops option is required when using volume type of 'io1'")
    end

    context 'when standard options and ebs-volume-type standard specified with provisioned-iops' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type standard  --provisioned-iops 123" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: --provisioned-iops option is only supported for volume type of 'io1'")
    end

    context 'when standard options and ebs-volume-type gp2 specified with provisioned-iops' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-volume-type gp2  --provisioned-iops 123" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: --provisioned-iops option is only supported for volume type of 'io1'")
    end

    context 'when standard options and provisioned-iops specified without ebs-volume-type io1' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node}  --provisioned-iops 123" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: --provisioned-iops option is only supported for volume type of 'io1'")
    end

    context 'when standard options and placement group specified with valid flavor' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --placement-group #{@placement_group} --flavor c3.large" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }
      
      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and placement group specified with invalid flavor' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --placement-group #{@placement_group} --flavor t1.micro" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: Please check if flavor t1.micro is supported for Placement groups.")
    end

    context 'when standard options and valid ebs size specified' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ebs-size 15 --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }
      
      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and valid ebs size and preserve ebs volume specified' do
      cmd_out = ""
      
      before { create_node_name("linux") }

      after { cmd_out = "#{cmd_output}" }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-size 15 --ebs-no-delete-on-term" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")

      it { check_and_delete_preserved_ebs_volume(cmd_out) }
    end

    context 'when standard options and invalid ebs size specified' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-size 5" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: EBS-size is smaller than snapshot")
    end

    context 'when standard options and ebs-optimized specified with valid flavor' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-optimized --flavor m1.large" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and ebs-optimized specified with invalid flavor' do
      before { create_node_name("linux") }
      
      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-optimized --flavor t1.micro" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }
    
      run_cmd_check_status_and_output("fail", "ERROR: Please check if flavor t1.micro is supported for EBS-optimized instances")
    end

    context 'when standard options and public subnet in vpc' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --subnet #{@subnet_id} --security-group-ids #{@security_group_ids} --associate-public-ip --server-connect-attribute public_ip_address" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and public subnet in vpc with security group name' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --subnet #{@subnet_id} --ec2-groups #{@ec2_groups} --associate-public-ip --server-connect-attribute public_ip_address" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "ERROR: You are using a VPC, security groups specified with '--ec2-groups' are not allowed")
    end

    context 'when standard options and chef node name prefix is default value(i.e ec2)' do
      let(:command) { "knife ec2 server create --ec2-groups #{@ec2_groups}" + append_ec2_creds + 
      get_linux_create_options + get_ssh_credentials }
      
      after { run(delete_instance_cmd("#{cmd_output}")) }
      
      run_cmd_check_status_and_output("succeed", "Bootstrapping Chef on")
    end

    context 'when standard options and chef node name prefix is user specified value' do
      let(:command) { "knife ec2 server create --ec2-groups #{@ec2_groups}" + append_ec2_creds + get_linux_create_options +
      " --chef-node-name-prefix ec2-integration-test-" + get_ssh_credentials }
      
      after { run(delete_instance_cmd("#{cmd_output}")) }

      run_cmd_check_status_and_output("succeed", "ec2-integration-test-")
    end

    context 'when standard options and delete-server-on-failure specified' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials +
      " --delete-server-on-failure" }
      
      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when delete-server-on-failure specified and bootstrap fails' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_linux_create_options(invalid_key = true) + get_ssh_credentials +
      " --delete-server-on-failure" }
      
      run_cmd_check_status_and_output("fail", "FATAL: Authentication Failed during bootstrapping")
    end

    context 'when ec2 credentials not specified' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" + 
      get_linux_create_options + get_ssh_credentials}

      run_cmd_check_status_and_output("fail", "ERROR: You did not provide a valid 'AWS Secret Access Key' value.")
    end

    context 'when ssh-password and identity-file parameters not specified' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} -I #{@ec2_linux_image} --server-url http://localhost:8889 --yes --server-create-timeout 1800 --template-file " + get_linux_template_file_path + append_ec2_creds }

      run_cmd_check_status_and_output("fail", "ERROR: You must provide either Identity file or SSH Password.")
    end

    context 'when invalid key_pair specified' do
      before { create_node_name("linux") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_linux_create_options + get_ssh_credentials(invalid_key_id = true) }

      run_cmd_check_status_and_output("fail", "FATAL: The key pair 'invalid_key_id' does not exist")
    end

    context 'when incorrect ec2 private_key.pem file is used' do
      server_create_common_bfr_aftr

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_linux_create_options(invalid_key = true) + 
      get_ssh_credentials }

      run_cmd_check_status_and_output("fail", "FATAL: Authentication Failed during bootstrapping")
    end
  end

  describe 'create and bootstrap Windows Server'  do
    before(:each) {rm_known_host}

    context 'when standard options specified' do
      cmd_out = ""

      before { create_node_name("windows") }

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_windows_create_options + get_winrm_credentials }

      after { cmd_out = "#{cmd_output}" }

      run_cmd_check_status_and_output("succeed", "#{@name_node}")

      context "delete server after create" do
        let(:command) { delete_instance_cmd(cmd_out) }
        run_cmd_check_status_and_output("succeed")
      end
    end

    context 'when standard options and ssh bootstrap protocol specified' do
      server_create_common_bfr_aftr("windows")

      let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
      append_ec2_creds + get_windows_create_options(bootstrap_protocol = "ssh") }
      
      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end

    context 'when standard options and ssh bootstrap protocol and user-data specified' do
      server_create_common_bfr_aftr("windows")

      let(:command) { "knife ec2 server create -N #{@name_node} --user-data #{ENV['EC2_USER_DATA']} --ec2-groups #{@ec2_groups}" + append_ec2_creds + get_windows_create_options(bootstrap_protocol = "ssh") }
      
      run_cmd_check_status_and_output("succeed", "#{@name_node}")
    end
  end
end