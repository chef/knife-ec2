#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#
require 'spec_helper'
require 'chef/knife/ec2_server_list'

describe Chef::Knife::Cloud::Ec2ServerList do
  let (:instance) {Chef::Knife::Cloud::Ec2ServerList.new}

  context "functionality" do
    before do
      @resources = [ TestResource.new({:id => "resource-1", :tags => {"Name" => "ubuntu01"}, :public_ip_address => "172.31.6.132", :private_ip_address => "172.31.6.133", :flavor_id => "m1.small", :image_id => "image01", :key_name => "keypair", :state => "ACTIVE", :groups => ['group1'], :iam_instance_profile => {}}),
                     TestResource.new({:id => "resource-2", :tags => {"Name" => "windows2008"}, :public_ip_address => "172.31.6.132", :private_ip_address => nil,  :flavor_id => "m1.micro", :image_id => "image02", :key_name => "keypair", :state => "ACTIVE", :groups => ['group2'], :iam_instance_profile => {}}),
                     TestResource.new({:id => "resource-3-err", :tags => {"Name" => "windows2008"} , :public_ip_address => nil, :private_ip_address => nil, :flavor_id => "m1.small", :image_id => "image02", :key_name => "keypair", :state => "ERROR", :groups => ['group3'], :iam_instance_profile => {}})
                   ]
      instance.stub(:query_resource).and_return(@resources)
      instance.stub(:puts)
      instance.stub_chain(:groups, :join)
      instance.stub(:create_service_instance).and_return(Chef::Knife::Cloud::Ec2Service.new)
      instance.stub(:validate!)
      instance.config[:name] = true
    end

    it "lists formatted list of resources" do
      instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", ""], :uneven_columns_across, 10)
      instance.run
    end

    it "lists formatted list of resources without Name column when --no-name option is set." do
      instance.config[:name] = false
      instance.ui.should_receive(:list).with(["Instance ID", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "resource-1", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", "resource-2", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", "resource-3-err", "", "", "m1.small", "image02", "keypair", "group3", "error", ""], :uneven_columns_across, 9)
      instance.run
    end

    context "when chef-data and chef-node-attribute set" do
      before(:each) do
        @resources.push(TestResource.new({:id => "server-4", :tags => {"Name" => "server-4"}, :public_ip_address => "172.31.6.132", :private_ip_address => "172.31.6.133", :flavor_id => "m1.small", :image_id => "image1", :key_name => "keypair", :state => "ACTIVE", :groups => ['group1'], :iam_instance_profile => {}}))
        @node = TestResource.new({:id => "server-4", :name => "server-4", :chef_environment => "_default", :fqdn => "testfqdnnode.us", :run_list => [], :tags => [], :platform => "ubuntu", :platform_family => "debian"})
        Chef::Node.stub(:list).and_return({"server-4" => @node})
        instance.config[:chef_data] = true
        instance.stub_chain(:groups, :join)
      end

      it "lists formatted list of resources on chef data option set" do
        instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "Chef Node Name", "Environment", "FQDN", "Runlist", "Tags", "Platform", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", "", "", "", "", "", "", "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", "", "", "", "", "", "", "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", "", "", "", "", "", "", "", "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", "", "server-4", "_default", "testfqdnnode.us", "[]", "[]", "ubuntu"], :uneven_columns_across, 16)
        instance.run
      end

      it "lists formatted list of resources on chef-data and chef-node-attribute option set" do
        instance.config[:chef_node_attribute] = "platform_family"
        instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "Chef Node Name", "Environment", "FQDN", "Runlist", "Tags", "Platform", "platform_family", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", "", "", "", "", "", "", "", "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", "", "", "", "", "", "", "", "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", "", "", "", "", "", "", "", "", "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", "", "server-4", "_default", "testfqdnnode.us", "[]", "[]", "ubuntu", "debian"], :uneven_columns_across, 17)
        @node.should_receive(:attribute?).with("platform_family").and_return(true)
        instance.run
      end

      it "raise error when chef-node-attribute is set to invalid" do
        instance.config[:chef_node_attribute] = "invalid_attribute"   
        @node.should_receive(:attribute?).with("invalid_attribute").and_return(false)
        instance.ui.should_receive(:fatal)
        instance.ui.should_receive(:error).with("The Node does not have a invalid_attribute attribute.")
        expect { instance.run }.to raise_error
      end

      it "should not display chef-data on chef-node-attribute set but chef-data option missing" do
        instance.config[:chef_data] = false
        instance.config[:chef_node_attribute] = "platform_family"
        instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", "", "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", ""], :uneven_columns_across, 10)
        instance.run
      end
    end

    context "when tags option is set." do
      before(:each) do
        @resources.push(TestResource.new({:id => "server-4", :tags => {"Name" => "server-4", "address" => "address01"}, :public_ip_address => "172.31.6.132", :private_ip_address => "172.31.6.133", :flavor_id => "m1.small", :image_id => "image1", :key_name => "keypair", :state => "ACTIVE", :groups => ['group1'], :iam_instance_profile => {}}))
        instance.config[:tags] = "address"
        instance.stub_chain(:groups, :join)
      end

      it "lists formatted list of resources with the tags column." do
        instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "Tags:address", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", nil, "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", nil, "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", "", nil, "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", "", "address01"], :uneven_columns_across, 11)
        instance.run
      end

      context "when tags option is set with multiple values." do
        before(:each) do
          @resources.push(TestResource.new({:id => "server-4", :tags => {"Name" => "server-4", "address" => "address01", "domain" => "test"}, :public_ip_address => "172.31.6.132", :private_ip_address => "172.31.6.133", :flavor_id => "m1.small", :image_id => "image1", :key_name => "keypair", :state => "ACTIVE", :groups => ['group1'], :iam_instance_profile => {}}))
          instance.config[:tags] = "address,domain"
          instance.stub_chain(:groups, :join)
        end

        it "lists formatted list of resources with the tags columns for each tag provided." do
          instance.ui.should_receive(:list).with(["Instance ID", "Name", "Public IP", "Private IP", "Flavor", "Image", "SSH Key", "Security Groups", "State", "IAM Profile", "Tags:address", "Tags:domain", "resource-1", "ubuntu01", "172.31.6.132", "172.31.6.133", "m1.small", "image01", "keypair", "group1", "active", "", nil, nil, "resource-2", "windows2008", "172.31.6.132", "", "m1.micro", "image02", "keypair", "group2", "active", "", nil, nil, "resource-3-err", "windows2008", "", "", "m1.small", "image02", "keypair", "group3", "error", "", nil, nil, "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", "", "address01", nil, "server-4", "server-4", "172.31.6.132", "172.31.6.133", "m1.small", "image1", "keypair", "group1", "active", "", "address01", "test"], :uneven_columns_across, 12)
          instance.run
        end
      end
    end
  end
end
