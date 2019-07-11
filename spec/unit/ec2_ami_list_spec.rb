  # License:: Apache License, Version 2.0
  #
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
  #

require File.expand_path("../../spec_helper", __FILE__)
require "aws-sdk-ec2"

describe Chef::Knife::Ec2AmiList do

  describe "#run" do
    let(:knife_ec2_ami_list) { Chef::Knife::Ec2AmiList.new }
    let(:ebs) { OpenStruct.new(volume_size: 30) }
    let(:block_device_mappings) { OpenStruct.new(ebs: ebs) }
    let(:image1) do
      OpenStruct.new(
        architecture: "x86_64",
        image_id: "im-34243rew32",
        platform: "windows",
        name: "image-test",
        description: "test windows winrm image",
        block_device_mappings: [block_device_mappings]
      )
    end

    let(:image2) do
      OpenStruct.new(
        architecture: "x86_64",
        image_id: "im-2532521",
        platform: "ubuntu",
        name: "ubuntu",
        description: "test ubuntu 14.04 image",
        block_device_mappings: [block_device_mappings]
      )
    end

    let(:image3) do
      OpenStruct.new(
        architecture: "x86_64",
        image_id: "im-435r54",
        platform: "fedora",
        name: "fedora",
        description: "test fedora image",
        block_device_mappings: [block_device_mappings]
      )
    end

    let(:ami_images)        { OpenStruct.new(images: [image1, image2, image3]) }
    let(:window_ami_images) { OpenStruct.new(images: [image1]) }
    let(:ubuntu_ami_images) { OpenStruct.new(images: [image2]) }
    let(:fedora_ami_images) { OpenStruct.new(images: [image3]) }
    let(:empty_images)      { OpenStruct.new(images: []) }
    let(:ec2_connection)    { Aws::EC2::Client.new(stub_responses: { describe_images: ami_images }) }

    before (:each) do
      knife_ec2_ami_list.config[:format] = "summary"
      allow(knife_ec2_ami_list).to receive(:ec2_connection).and_return ec2_connection
    end

    it "invokes validate_aws_config!" do
      allow(knife_ec2_ami_list.ui).to receive(:warn)
      expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
      knife_ec2_ami_list.run
    end

    context "when region is not specified" do
      it "shows warning that default region will be will be used" do
        knife_ec2_ami_list.config.delete(:region)
        Chef::Config[:knife].delete(:region)
        allow(ec2_connection).to receive(:describe_images).and_return(empty_images)
        allow(knife_ec2_ami_list).to receive(:validate_aws_config!)
        expect(knife_ec2_ami_list.ui).to receive(:warn).with("No region was specified in knife.rb/config.rb or as an argument. The default region, us-east-1, will be used:")
        output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
        output_column_count = output_column.length
        expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
        knife_ec2_ami_list.run
      end
    end

    context "when --owner is passed" do
      before do
        allow(knife_ec2_ami_list.ui).to receive(:warn)
        allow(knife_ec2_ami_list).to receive(:custom_warnings!)
        knife_ec2_ami_list.config[:use_iam_profile] = true
      end

      context "When value for owner is nil" do
        it "shows the available AMIs List" do
          knife_ec2_ami_list.config[:owner] = nil
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          images = ec2_connection.describe_images.images
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          images.each do |image|
            output_column << image.image_id
            output_column << (image.platform ? image.platform : image.name.split(/\W+/).first)
            output_column << image.architecture
            output_column << image.block_device_mappings[0].ebs.volume_size.to_s
            output_column << image.name.split(/\W+/).first
            output_column << image.description
          end
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When value for owner is self" do
        it "does not raise any error" do
          knife_ec2_ami_list.config[:owner] = "self"
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          allow(ec2_connection).to receive(:describe_images).and_return(ami_images)
          expect { knife_ec2_ami_list.validate_aws_config! }.not_to raise_error
        end
      end

      context "When value for owner is microsoft" do
        it "does not raise any error" do
          knife_ec2_ami_list.config[:owner] = "microsoft"
          allow(ec2_connection).to receive(:describe_images).and_return(ami_images)
          expect { knife_ec2_ami_list.validate_aws_config! }.not_to raise_error
        end
      end

      context "When value for owner is aws-marketplace" do
        it "does not raise any error" do
          knife_ec2_ami_list.config[:owner] = "aws-marketplace"
          allow(ec2_connection).to receive(:describe_images).and_return(ami_images)
          expect { knife_ec2_ami_list.validate_aws_config! }.not_to raise_error
        end
      end

      context "When owner is invalid" do
        it "raises error" do
          allow(knife_ec2_ami_list).to receive(:puts)
          expect(lambda { knife_ec2_ami_list.parse_options(["--owner", "xyz"]) }).to raise_error(SystemExit)
        end
      end
    end

    context "when --platform is passed" do
      before do
        allow(knife_ec2_ami_list.ui).to receive(:warn)
        allow(knife_ec2_ami_list).to receive(:custom_warnings!)
      end

      context "When platform is nil" do
        it "shows all the AMIs List" do
          knife_ec2_ami_list.config[:platform] = nil
          allow(ec2_connection).to receive(:describe_images).and_return(ami_images)
          images = ec2_connection.describe_images.images
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          images.each do |image|
            output_column << image.image_id
            output_column << (image.platform ? image.platform : image.name.split(/\W+/).first)
            output_column << image.architecture
            output_column << image.block_device_mappings[0].ebs.volume_size.to_s
            output_column << image.name.split(/\W+/).first
            output_column << image.description
          end
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When platform is windows" do
        it "shows only windows AMIs List" do
          knife_ec2_ami_list.config[:platform] = "windows"
          allow(ec2_connection).to receive(:describe_images).and_return(window_ami_images)
          window_image = ec2_connection.describe_images.images.first
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << window_image.image_id
          output_column << window_image.platform
          output_column << window_image.architecture
          output_column << window_image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << window_image.name.split(/\W+/).first
          output_column << window_image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When platform is ubuntu" do
        it "shows only ubuntu AMIs List" do
          knife_ec2_ami_list.config[:platform] = "ubuntu"
          allow(ec2_connection).to receive(:describe_images).and_return(ubuntu_ami_images)
          ubuntu_image = ec2_connection.describe_images.images.first
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << ubuntu_image.image_id
          output_column << ubuntu_image.platform
          output_column << ubuntu_image.architecture
          output_column << ubuntu_image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << ubuntu_image.name.split(/\W+/).first
          output_column << ubuntu_image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When platform is fedora" do
        it "shows only fedora AMIs List" do
          knife_ec2_ami_list.config[:platform] = "fedora"
          allow(ec2_connection).to receive(:describe_images).and_return(fedora_ami_images)
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          fedora_image = ec2_connection.describe_images.images.last
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << fedora_image.image_id
          output_column << fedora_image.platform
          output_column << fedora_image.architecture
          output_column << fedora_image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << fedora_image.name.split(/\W+/).first
          output_column << fedora_image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When platform is invalid" do
        it "raises error" do
          allow(knife_ec2_ami_list).to receive(:puts)
          expect(lambda { knife_ec2_ami_list.parse_options(["--platform", "xyz"]) }).to raise_error(SystemExit)
        end
      end
    end

    context "when --search is passed" do
      before do
        allow(knife_ec2_ami_list.ui).to receive(:warn)
        allow(knife_ec2_ami_list).to receive(:custom_warnings!)
      end

      context "When search key word is present in description" do
        it "shows only AMIs List that have 14.04 in description" do
          knife_ec2_ami_list.config[:search] = "14.04"
          allow(ec2_connection).to receive(:describe_images).and_return(ubuntu_ami_images)
          image = ec2_connection.describe_images.images.first
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << image.image_id
          output_column << image.platform
          output_column << image.architecture
          output_column << image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << image.name.split(/\W+/).first
          output_column << image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When user pass platform and search keyword" do
        it "shows only AMIs List that have 14.04 in description and platform is ubuntu" do
          knife_ec2_ami_list.config[:platform] = "ubuntu"
          knife_ec2_ami_list.config[:search] = "14.04"
          allow(ec2_connection).to receive(:describe_images).and_return(ubuntu_ami_images)
          ubuntu_image = ec2_connection.describe_images.images.first
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << ubuntu_image.image_id
          output_column << ubuntu_image.platform
          output_column << ubuntu_image.architecture
          output_column << ubuntu_image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << ubuntu_image.name.split(/\W+/).first
          output_column << ubuntu_image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When user pass owner, platform and search keyword" do
        it "shows only AMIs List that owner microsoft platform windows and search keyword is winrm" do
          knife_ec2_ami_list.config[:owner] = "microsoft"
          knife_ec2_ami_list.config[:platform] = "windows"
          knife_ec2_ami_list.config[:search] = "winrm"
          allow(ec2_connection).to receive(:describe_images).and_return(window_ami_images)
          ubuntu_image = ec2_connection.describe_images.images.first
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          output_column << ubuntu_image.image_id
          output_column << ubuntu_image.platform
          output_column << ubuntu_image.architecture
          output_column << ubuntu_image.block_device_mappings[0].ebs.volume_size.to_s
          output_column << ubuntu_image.name.split(/\W+/).first
          output_column << ubuntu_image.description
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end

      context "When search key word is not present in description" do
        it "Fetch no AMI" do
          knife_ec2_ami_list.config[:search] = "Not present"
          allow(ec2_connection).to receive(:describe_images).and_return(empty_images)
          expect(knife_ec2_ami_list).to receive(:validate_aws_config!)
          output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
          output_column_count = output_column.length
          expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column, :uneven_columns_across, output_column_count)
          knife_ec2_ami_list.run
        end
      end
    end
  end
end
