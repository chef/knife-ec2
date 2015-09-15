# Author:: Ameya Varade (<ameya.varade@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

shared_examples_for "ec2 command with validations" do |instance|

  describe "#validate!" do
    before(:each) do
      Chef::Config[:knife][:aws_access_key_id] = "testaccesskey"
      Chef::Config[:knife][:aws_secret_access_key] = "testaccesssecret"
      allow(instance).to receive(:exit)
    end

    it "validate ec2 mandatory options" do
      expect {instance.validate!}.to_not raise_error
    end

    it "raise error on aws_access_key_id missing" do
      Chef::Config[:knife].delete(:aws_access_key_id)
      expect(instance.ui).to receive(:error).with("You did not provide a valid 'AWS Access Key Id' value.")
      expect { instance.validate! }.to raise_error(Chef::Knife::Cloud::CloudExceptions::ValidationError)
    end

    it "raise error on aws_secret_access_key missing" do
      Chef::Config[:knife].delete(:aws_secret_access_key)
      expect(instance.ui).to receive(:error).with("You did not provide a valid 'AWS Secret Access Key' value.")
      expect { instance.validate! }.to raise_error(Chef::Knife::Cloud::CloudExceptions::ValidationError)
    end

    context "with aws_credential_file" do
      before(:each) do
        Chef::Config[:knife][:aws_credential_file] = "creds_file_path"
        Chef::Config[:knife][:aws_profile] = "default"
      end

      after(:each) do
        Chef::Config[:knife].delete(:aws_credential_file)
        Chef::Config[:knife].delete(:aws_profile)
      end

      it "raise error while specifying credentials file and aws keys together." do
        allow(File).to receive(:read).and_return("[default]\nAWSAccessKeyId=b\nAWSSecretKey=a")
        expect(instance.ui).to receive(:error).with("Either provide a credentials file or the access key and secret keys but not both.")
        expect(lambda { instance.validate! }).to raise_error
      end

      it "validate ec2 mandatory options when aws_credential_file is not provided." do
        Chef::Config[:knife].delete(:aws_credential_file)
        expect {instance.validate!}.to_not raise_error
      end

      it "raise error while specifying credentials file with only aws_access_key_id." do
        Chef::Config[:knife].delete(:aws_access_key_id)
        Chef::Config[:knife].delete(:aws_secret_access_key)
        allow(File).to receive(:read).and_return("[default]\nAWSAccessKeyId=b")
        expect(instance.ui).to receive(:error).with("You did not provide a valid 'AWS Secret Access Key' value.")
        expect(lambda { instance.validate! }).to raise_error
      end

      it "raise error while specifying credentials file with only aws_secret_access_key." do
        Chef::Config[:knife].delete(:aws_access_key_id)
        Chef::Config[:knife].delete(:aws_secret_access_key)
        allow(File).to receive(:read).and_return("[default]\nAWSSecretKey=a")
        expect(instance.ui).to receive(:error).with("You did not provide a valid 'AWS Access Key Id' value.")
        expect(lambda { instance.validate! }).to raise_error
      end

    end
  end
end
