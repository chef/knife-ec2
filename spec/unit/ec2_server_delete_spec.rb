require 'spec_helper'
require 'chef/knife/ec2_server_delete'
require 'chef/knife/cloud/ec2_service'
require 'support/shared_examples_for_serverdeletecommand'

describe Chef::Knife::Cloud::Ec2ServerDelete do

  ec2_server_delete = Chef::Knife::Cloud::Ec2ServerDelete.new
  ec2_server_delete.config[:chef_node_name] = "testserver"

  it_behaves_like Chef::Knife::Cloud::ServerDeleteCommand, ec2_server_delete

  let (:instance) {Chef::Knife::Cloud::Ec2ServerDelete.new}

  before(:each) do
    instance.stub(:exit)
  end

  context "#validate!" do

    before(:each) do
      Chef::Config[:knife][:aws_access_key_id] = "testaccesskey"
      Chef::Config[:knife][:aws_secret_access_key] = "testaccesssecret"
      instance.stub(:exit)
    end

    it "validate ec2 mandatory options" do
      expect {instance.validate!}.to_not raise_error
    end

    it "raise error on aws_access_key_id missing" do
      Chef::Config[:knife].delete(:aws_access_key_id)
      instance.ui.should_receive(:error).with("You did not provide a valid 'AWS Access Key Id' value.")
      expect { instance.validate! }.to raise_error(Chef::Knife::Cloud::CloudExceptions::ValidationError)
    end

    it "raise error on aws_secret_access_key missing" do
      Chef::Config[:knife].delete(:aws_secret_access_key)
      instance.ui.should_receive(:error).with("You did not provide a valid 'AWS Secret Access Key' value.")
      expect { instance.validate! }.to raise_error(Chef::Knife::Cloud::CloudExceptions::ValidationError)
    end
  end

  context "with aws_credential_file" do
    before(:each) do
      Chef::Config[:knife][:aws_credential_file] = "creds_file_path"
    end

    after(:each) do
      Chef::Config[:knife].delete(:aws_credential_file)
    end

    it "raise error while specifying credentials file and aws keys together." do
      File.stub(:read).and_return("AWSAccessKeyId=b\nAWSSecretKey=a")
      instance.ui.should_receive(:error).with("Either provide a credentials file or the access key and secret keys but not both.")
      lambda { instance.validate! }.should raise_error 
    end

    it "validate ec2 mandatory options when aws_credential_file is not provided." do
      Chef::Config[:knife].delete(:aws_credential_file)
      expect {instance.validate!}.to_not raise_error 
    end

    it "raise error while specifying credentials file with only aws_access_key_id." do
      Chef::Config[:knife].delete(:aws_access_key_id)
      Chef::Config[:knife].delete(:aws_secret_access_key)
      File.stub(:read).and_return("AWSAccessKeyId=b")
      instance.ui.should_receive(:error).with("You did not provide a valid 'AWS Secret Access Key' value.")
      lambda { instance.validate! }.should raise_error 
    end

    it "raise error while specifying credentials file with only aws_secret_access_key." do
      Chef::Config[:knife].delete(:aws_access_key_id)
      Chef::Config[:knife].delete(:aws_secret_access_key)
      File.stub(:read).and_return("AWSSecretKey=a")
      instance.ui.should_receive(:error).with("You did not provide a valid 'AWS Access Key Id' value.")
      lambda { instance.validate! }.should raise_error 
    end
  end

  # Test for delete_from_chef extended functionality
  context "#delete_from_chef" do
    it "fetch node name using server_name when config[:chef_node_name] is missing and --purge set" do
      server_name = "test_server"
      instance.config[:purge] = true
      instance.config[:chef_node_name] = nil
      instance.stub_chain(:destroy_item, :query)
      instance.should_receive(:fetch_node_name).with(server_name).and_return("testnode")
      instance.delete_from_chef(server_name)
    end

    it "dont fetch_node_name when config[:chef_node_name] and --purge are set" do
      server_name = "test_server"
      instance.config[:purge] = true
      instance.config[:chef_node_name] = "testnode"
      instance.stub_chain(:destroy_item, :query)
      instance.should_not_receive(:fetch_node_name)
      instance.delete_from_chef(server_name)
    end
  end

  # Test for execute_command extended functionality
  context "#execute_command" do
    it "get instance id by using chef_node_name" do
      instance.service = double
      chef_node_name = "testnode"
      instance.stub(:ui).and_return(double)
      instance.config[:chef_node_name] = chef_node_name
      instance.should_receive(:fetch_instance_id).with(chef_node_name).and_return("instance_id")
      instance.ui.should_receive(:info).with("No Instance Id is specified, trying to retrieve it from node name")
      instance.service.should_receive(:delete_server)
      instance.should_receive(:delete_from_chef)
      instance.execute_command
    end
  end

  context "#fetch_node_name" do
    it "uses chef search" do
      instance_id = "i-89dw90"
      instance.stub(:query).and_return(double)
      instance.query.should_receive(:search).with(:node, "ec2_instance_id:#{instance_id}").and_return([[]])
      instance.fetch_node_name(instance_id)
    end
  end

  context "#fetch_instance_id" do
    it "uses chef search" do
      chef_node_name = "testnode"
      instance.stub(:query).and_return(double)
      instance.query.should_receive(:search).with(:node, "name:#{chef_node_name}").and_return([[]])
      instance.fetch_instance_id(chef_node_name)
    end
  end

  context "#query" do
    it "returns chef query object" do
      Chef::Search::Query.should_receive(:new)
      instance.query
    end
  end  
end
