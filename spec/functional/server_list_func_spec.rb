require 'spec_helper'
require 'chef/knife/ec2_server_list'

describe Chef::Knife::Cloud::Ec2ServerList do
  let (:instance) {Chef::Knife::Cloud::Ec2ServerList.new}

  context "functionality" do
    before do
      @resources = [ TestResource.new({:id => "resource-1", :tags => {"Name" => "ubuntu01"}, :public_ip_address => "172.31.6.132", :private_ip_address => "172.31.6.133", :flavor_id => "m1.small", :image_id => "image01", :key_name => "keypair", :state => "ACTIVE"}),
                     TestResource.new({:id => "resource-2", :tags => {"Name" => "windows2008"}, :public_ip_address => "172.31.6.132", :private_ip_address => nil,  :flavor_id => "m1.micro", :image_id => "image02", :key_name => "keypair", :state => "ACTIVE"}),
                     TestResource.new({:id => "resource-3-err", :tags => {"Name" => "windows2008"} , :public_ip_address => nil, :private_ip_address => nil, :flavor_id => "m1.small", :image_id => "image02", :key_name => "keypair", :state => "ERROR"})
                   ]
      instance.stub(:query_resource).and_return(@resources)
      instance.stub(:puts)
      instance.stub(:create_service_instance).and_return(Chef::Knife::Cloud::Service.new)
      instance.stub(:validate!)
    end

    it "lists formatted list of resources" do
      instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "Keypair", "State",
                                              "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01","keypair", "ACTIVE", "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "ACTIVE",
                                              "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "ERROR"
                                              ], :uneven_columns_across, 8)
      instance.run
    end
  end
end
