# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

require 'spec_helper'
require 'chef/knife/ec2_server_list'
require 'chef/knife/cloud/ec2_service'
require 'support/shared_examples_for_command'
require 'support/shared_examples_for_unit_tests'

describe Chef::Knife::Cloud::Ec2ServerList do
  it_behaves_like Chef::Knife::Cloud::Command, Chef::Knife::Cloud::Ec2ServerList.new
  it_behaves_like "ec2 command with validations", Chef::Knife::Cloud::Ec2ServerList.new  
end
