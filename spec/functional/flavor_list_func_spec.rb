# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

require 'spec_helper'
require 'chef/knife/ec2_flavor_list'
require 'chef/knife/cloud/ec2_service'
require 'support/shared_examples_for_command'

describe Chef::Knife::Cloud::Ec2FlavorList do
  let (:instance) {Chef::Knife::Cloud::Ec2FlavorList.new}

  context "functionality" do
    before do
      resources = [ TestResource.new({:id => "resource-1", :name => "m1.small", :ram => 512, :disk => 0, :bits => 32, :cores => 5}),
                     TestResource.new({:id => "resource-2", :name => "t1.micro", :ram => 7680, :disk => 420, :bits => 64, :cores => 2})
                   ]
      instance.stub(:query_resource).and_return(resources)
      instance.stub(:puts)
      instance.stub(:create_service_instance).and_return(Chef::Knife::Cloud::Service.new)
      instance.stub(:validate!)
    end

    it "lists formatted list of resources" do
      instance.ui.should_receive(:list).with(["ID", "Name", "RAM", "Disk", "Bits", "Cores",
                                              "resource-1", "m1.small", "512 MB", "0 GB", "32", "5",
                                              "resource-2", "t1.micro", "7680 MB", "420 GB", "64", "2"], :uneven_columns_across, 6)
      instance.run
    end
  end
end