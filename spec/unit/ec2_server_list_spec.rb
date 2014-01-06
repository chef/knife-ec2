#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
#

require 'spec_helper'
require 'chef/knife/ec2_server_list'
require 'chef/knife/cloud/ec2_service'
require 'support/shared_examples_for_command'

describe Chef::Knife::Cloud::Ec2ServerList do
  it_behaves_like Chef::Knife::Cloud::Command, Chef::Knife::Cloud::Ec2ServerList.new

  let (:instance) {Chef::Knife::Cloud::Ec2ServerList.new}

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
  end
end
