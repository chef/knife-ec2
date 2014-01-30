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

def get_ssh_credentials
  " --ssh-user #{@ec2_ssh_user}"+
  " --ec2-ssh-key-id #{@ec2_ssh_key_id}"
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
      end
    end
  end
end