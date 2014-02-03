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
  ec2_win_create_cmd = " -I #{@ec2_windows_image} " +
  " --template-file " + get_windows_msi_template_file_path +
  " --server-url http://localhost:8889" +
  " --identity-file #{temp_dir}/ec2.pem" +
  " --yes --server-create-timeout 1800"
  if bootstrap_protocol == "winrm"
    ec2_win_create_cmd += " --bootstrap-protocol winrm" + " --user-data #{ENV['EC2_USER_DATA']}"
  else
    ec2_win_create_cmd += " --bootstrap-protocol ssh --ec2-ssh-key-id #{@ec2_ssh_key_id}" + " --ssh-user #{@ec2_windows_ssh_user} --ssh-password #{@ec2_windows_ssh_password}"
  end
  ec2_win_create_cmd
end

def get_ssh_credentials_for_windows_image
  " --ssh-user #{@ec2_windows_ssh_user}"+
  " --ssh-password #{@ec2_windows_ssh_password}"
end

def rm_known_host
  known_hosts = File.expand_path("~") + "/.ssh/known_hosts"
  FileUtils.rm_rf(known_hosts)
end

describe 'knife-ec2' , :if => is_config_present do
  include KnifeTestBed
  include RSpec::KnifeTestUtils

  before(:all) do
    run('gem build knife-ec2.gemspec').exitstatus.should == 0
    run("gem install #{get_gem_file_name}").exitstatus.should == 0
    init_ec2_test
  end

  after(:all) do
    run("gem uninstall knife-ec2 -v '#{Knife::Ec2::VERSION}'")
    cleanup_test_data
  end

  context 'gem' do
    describe 'knife' do
      context 'ec2' do
        context 'flavor list --help' do
         let(:command) { "knife ec2 flavor list --help" }
           it 'should list all the options available for flavors list command.' do
            match_stdout(/--help/)
          end
        end

        context 'server create --help' do
         let(:command) { "knife ec2 server create --help" }
           it 'should list all the options available for server create command.' do
            match_stdout(/--help/)
          end
        end

        context 'server delete --help' do
         let(:command) { "knife ec2 server delete --help" }
           it 'should list all the options available for server delete command.' do
            match_stdout(/--help/)
          end
        end

        context 'server list --help' do
         let(:command) { "knife ec2 server list --help" }
           it 'should list all the options available for server list command.' do
            match_stdout(/--help/)
          end
        end

        context 'server list' do
          let(:command) { "knife ec2 server list" + append_ec2_creds }
          it 'should successfully list all the servers.' do
            match_status("should succeed")
          end
        end
        
        context 'server list with --availability-zone' do
          let(:command) { "knife ec2 server list" + append_ec2_creds + " --availability-zone"}
          it 'should successfully list all the servers with availability-zone details.' do
            match_status("should succeed")
          end
        end

        context 'server list without instance name attribute' do
          let(:command) { "knife ec2 server list" + append_ec2_creds + " --no-name"}
          it 'should successfully list all the servers without Instance Name field' do
            match_status("should succeed")
          end
        end

        context 'server list with tags' do
          let(:command) { "knife ec2 server list" + append_ec2_creds + " -t name"}
          it 'should successfully list all the servers with given tag.' do
            match_status("should succeed")
          end
        end

        context 'flavor list' do
          let(:command) { "knife ec2 flavor list" + append_ec2_creds }
          it 'should successfully list all the available flavors.' do
            match_status("should succeed")
          end
        end
        
        describe 'Cerate and bootstrap Linux Server'  do
          before(:each) {rm_known_host}

          context 'with standard options' do
            cmd_out = ""
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }
            
            after(:each) do
              cmd_out = "#{cmd_stdout}"
            end

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end

            context "delete server after create" do
              let(:command) { delete_instance_cmd(cmd_out) }
              it "should successfully delete the server." do
                match_status("should succeed")
              end
            end
          end

          context 'with standard options and invalid ec2 security group' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups invalid-#{SecureRandom.hex(4)}" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            it 'should throw error and fail to create server.' do
              match_status("should fail")
            end
          end

          context 'with standard options and placement group with valid flavor' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --placement-group #{@placement_group} --flavor m1.large" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and placement group with invalid flavor' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --placement-group #{@placement_group} --flavor t1.micro" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            it 'should throw error and fail to create server.' do
              match_status("should fail")
            end
          end

          context 'with standard options and valid ebs size' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ebs-size 15 --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and valid ebs size and preserve ebs volume after instance delete' do
            before(:each) { create_node_name("linux") }
            
            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-size 15 --ebs-no-delete-on-term" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
              puts("Preserved ebs volume, Please delete it by using AWS console")
            end
          end

          context 'with standard options and invalid ebs size' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-size 5" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            it 'should throw error message and fail to create server.' do
              match_status("should fail")
            end
          end

          context 'with standard options and ebs-optimized with valid flavor' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-optimized --flavor m1.large" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and ebs-optimized with invalid flavor' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --ebs-optimized --flavor t1.micro" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            it 'should throw error message and fail to create server.' do
              match_status("should fail")
            end
          end

          context 'with standard options and public subnet in vpc' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} --subnet #{@subnet_id} --security-group-ids #{@security_group_ids} --associate-public-ip --server-connect-attribute public_ip_address" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and public subnet in vpc with security group name' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --subnet #{@subnet_id} --ec2-groups #{@ec2_groups} --associate-public-ip --server-connect-attribute public_ip_address" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials }

            it 'should throw error and fail to create server.' do
              match_status("should fail")
            end
          end

          context 'with standard options and chef node name prefix default value(i.e ec2)' do
            let(:command) { "knife ec2 server create --ec2-groups #{@ec2_groups}" + append_ec2_creds + 
            get_linux_create_options + get_ssh_credentials }
            
            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }
            
            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and chef node name prefix user specified value' do
            let(:command) { "knife ec2 server create --ec2-groups #{@ec2_groups}" + append_ec2_creds + get_linux_create_options +
            " --chef-node-name-prefix ec2-integration-test-" + get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }

            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and delete-server-on-failure' do
            before(:each) { create_node_name("linux") }
            
            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials +
            " --delete-server-on-failure" }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }
            
            it 'should successfully create the server with the provided options.' do
              match_status("should succeed")
            end
          end

          context 'with standard options and delete-server-on-failure' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options(invalid_key = true) + get_ssh_credentials +
            " --delete-server-on-failure" }

            it 'should delete server on bootstrap failure' do
              match_status("should fail")
            end
          end

          context 'without ec2 credentials' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" + 
            get_linux_create_options + get_ssh_credentials}
            
            it 'should throw error message and stop execution.' do
              match_status("should fail")
            end
          end

          context 'without ssh-password and identity-file parameters' do
            cmd_out = ""
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups} -I #{@ec2_linux_image} --server-url http://localhost:8889 --yes --server-create-timeout 1800 --template-file " + get_linux_template_file_path + append_ec2_creds }
            
            it 'should throw error message and stop execution.' do
              match_status("should fail")
            end
          end

          context 'with invalid key_pair' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options + get_ssh_credentials(invalid_key_id = true) }
            
            it 'should throw error message and stop execution.' do
              match_status("should fail")
            end
          end

          context 'with incorrect ec2 private_key.pem file' do
            before(:each) { create_node_name("linux") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_linux_create_options(invalid_key = true) + 
            get_ssh_credentials }

            after(:each)  { run(delete_instance_cmd("#{cmd_stdout}")) }
            
            it 'should throw Error message and stop execution.' do
              match_status("should fail")
            end
          end
        end

        describe 'Cerate and bootstrap Windows Server'  do
          before(:each) {rm_known_host}

          context 'with standard options' do
            cmd_out = ""
            before(:each) { create_node_name("windows") }

            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_windows_create_options + get_winrm_credentials }

            after(:each) do
              cmd_out = "#{cmd_stdout}"
            end
            
            it 'should successfully create the (windows VM) server with the provided options.' do
              match_status("should succeed")
            end

            context "delete server after create" do
              let(:command) { delete_instance_cmd(cmd_out) }

              it "should successfully delete the server." do
                match_status("should succeed")
              end
            end
          end

          context 'with standard options and ssh bootstrap protocol' do
            cmd_out = ""
            before(:each) { create_node_name("windows") }
            
            let(:command) { "knife ec2 server create -N #{@name_node} --ec2-groups #{@ec2_groups}" +
            append_ec2_creds + get_windows_create_options(bootstrap_protocol = "ssh") }

            after(:each) do
              cmd_out = "#{cmd_stdout}"
            end
            
            it 'should successfully create the (windows VM) server with the provided options.' do
              match_status("should succeed")
            end

            context "delete server after create" do
              let(:command) { delete_instance_cmd(cmd_out) }

              it "should successfully delete the server." do
                match_status("should succeed")
              end
            end
          end
        end
      end
    end
  end
end