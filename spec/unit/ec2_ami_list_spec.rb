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

  require File.expand_path('../../spec_helper', __FILE__)
  require 'fog/aws'

  describe Chef::Knife::Ec2AmiList do

    describe '#run' do
      let(:knife_ec2_ami_list) { Chef::Knife::Ec2AmiList.new }
      let(:ec2_connection) { double(Fog::Compute::AWS) }
      before (:each) do
        allow(knife_ec2_ami_list).to receive(:connection).and_return(ec2_connection)
        @describe_images_format = double("describe_image_output", :body => { 
              'imagesSet'    => [{
              'architecture'        => "x86_64",
              'blockDeviceMapping'  => [{"deviceName"=>"/dev/sda1",
                                         "snapshotId"=>"snap-f7e645f4",
                                         "volumeSize"=>30,
                                         "deleteOnTermination"=>"true",
                                         "volumeType"=>"standard",
                                         "encrypted"=>"false"}],
              'description'         => "window winrm",
              'hypervisor'          => "xen",
              'imageId'             => "ami-4ace6d23",
              'imageLocation'       => "microsoft/Windows_Server-2008-R2-SP1-English-64Bit-WebMatrix_Hosting-2012.06.12",
              'imageOwnerAlias'     => "microsoft",
              'name'                => "Windows_Server-2008-R2-SP1-English-64Bit-Windows_Media_Services_4.1-2012.06.12",
              'imageOwnerId'        => "461346954234",
              'imageState'          => "available",
              'imageType'           => "machine",
              'isPublic'            => true,
              'platform'            => "windows",
              'productCodes'        => [],
              'rootDeviceName'      => "/dev/sda1",
              'rootDeviceType'      => "ebs",
              'stateReason'         => {},
              'tagSet'              => {},
              'virtualizationType'  => "hvm"
            }, {
              'architecture'        => "i386",
              'blockDeviceMapping'  => [{"deviceName"=>"/dev/sda1",
                                         "snapshotId"=>"snap-f7e645f4",
                                         "volumeSize"=>10,
                                         "deleteOnTermination"=>"true",
                                         "volumeType"=>"standard",
                                         "encrypted"=>"false"}],
              'description'         => "DC for Quan",
              'hypervisor'          => "xen",
              'imageId'             => "ami-4ace6d21",
              'imageOwnerAlias'     => "aws-marketplace",
              'name'                => "ubuntu i386",
              'imageOwnerId'        => "461346954235",
              'imageState'          => "available",
              'imageType'           => "machine",
              'isPublic'            => true,
              'productCodes'        => [],
              'rootDeviceName'      => "/dev/sda1",
              'rootDeviceType'      => "ebs",
              'stateReason'         => {},
              'tagSet'              => {},
              'virtualizationType'  => "hvm"
            }, {
              'architecture'        => "x86_64",
              'blockDeviceMapping'  => [{"deviceName"=>"/dev/sda1",
                                         "snapshotId"=>"snap-f7e645f4",
                                         "volumeSize"=>8,
                                         "deleteOnTermination"=>"true",
                                         "volumeType"=>"standard",
                                         "encrypted"=>"false"}],
              'description'         => "ubuntu 14.04",
              'hypervisor'          => "xen",
              'imageId'             => "ami-4ace6d29",
              'imageOwnerAlias'     => "aws-marketplace",
              'name'                => "fedora i64",
              'imageOwnerId'        => "461346954234",
              'imageState'          => "available",
              'imageType'           => "machine",
              'isPublic'            => true,
              'productCodes'        => [],
              'rootDeviceName'      => "/dev/sda1",
              'rootDeviceType'      => "ebs",
              'stateReason'         => {},
              'tagSet'              => {},
              'virtualizationType'  => "hvm"
            }],
          'requestId'     => "ba38c315-f1b4-4822-b336-6309bed6d50c"
          }
        )
      end

      it 'invokes validate!' do
        allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
        allow(knife_ec2_ami_list.ui).to receive(:warn)
        expect(knife_ec2_ami_list).to receive(:validate!)
        knife_ec2_ami_list.run
      end

      context 'when region is not specified' do
        it 'shows warning that default region will be will be used' do
          knife_ec2_ami_list.config.delete(:region)
          Chef::Config[:knife].delete(:region)
          ec2_servers = double()
          allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
          allow(knife_ec2_ami_list).to receive(:validate!)
          expect(knife_ec2_ami_list.ui).to receive(:warn).with("No region was specified in knife.rb or as an argument. The default region, us-east-1, will be used:")
          knife_ec2_ami_list.run
        end
      end

      context 'when --owner is passed' do
        before do
          allow(knife_ec2_ami_list.ui).to receive(:warn)
          allow(knife_ec2_ami_list).to receive(:custom_warnings!)
          knife_ec2_ami_list.config[:use_iam_profile] = true
        end

        context 'When value for owner is nil' do
          it 'shows the available AMIs List' do
            knife_ec2_ami_list.config[:owner] = nil
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect(knife_ec2_ami_list).to receive(:validate!)
            images = ec2_connection.describe_images.body['imagesSet']
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            images.each do |image|
              output_column << image["imageId"].to_s
              output_column << (image["platform"] ?  image["platform"] : image["name"].split(/\W+/).first)
              output_column << image["architecture"].to_s
              output_column << image["blockDeviceMapping"].first["volumeSize"].to_s
              output_column << image["name"].split(/\W+/).first
              output_column << image["description"]
            end
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When value for owner is self' do
          it 'does not raise any error' do
            knife_ec2_ami_list.config[:owner] = 'self'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect{ knife_ec2_ami_list.validate! }.not_to raise_error
          end
        end

        context 'When value for owner is microsoft' do
          it 'does not raise any error' do
            knife_ec2_ami_list.config[:owner] = 'microsoft'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect{ knife_ec2_ami_list.validate! }.not_to raise_error
          end
        end

        context 'When value for owner is aws-marketplace' do
          it 'does not raise any error' do
            knife_ec2_ami_list.config[:owner] = 'aws-marketplace'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect{ knife_ec2_ami_list.validate! }.not_to raise_error
          end
        end

        context 'When owner is invalid' do
          it 'raises error' do
            knife_ec2_ami_list.config[:owner] = 'xyz'
            knife_ec2_ami_list.config[:use_iam_profile] = true
            expect{ knife_ec2_ami_list.validate! }.to raise_error "Invalid owner: #{knife_ec2_ami_list.config[:owner]}. Allowed owners are self, aws-marketplace or microsoft."
          end
        end
      end

      context 'when --platform is passed' do
        before do
          allow(knife_ec2_ami_list.ui).to receive(:warn)
          allow(knife_ec2_ami_list).to receive(:custom_warnings!)
        end

        context 'When platform is nil' do
          it 'shows all the AMIs List' do
            knife_ec2_ami_list.config[:platform] = nil
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            images = ec2_connection.describe_images.body['imagesSet']
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            images.each do |image|
              output_column << image["imageId"].to_s
              output_column << (image["platform"] ?  image["platform"] : image["name"].split(/\W+/).first)
              output_column << image["architecture"].to_s
              output_column << image["blockDeviceMapping"].first["volumeSize"].to_s
              output_column << image["name"].split(/\W+/).first
              output_column << image["description"]
            end
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When platform is windows' do
          it 'shows only windows AMIs List' do
            knife_ec2_ami_list.config[:platform] = 'windows'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            window_image = ec2_connection.describe_images.body['imagesSet'].first
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << window_image["imageId"]
            output_column << window_image["platform"]
            output_column << window_image["architecture"]
            output_column << window_image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << window_image["name"].split(/\W+/).first
            output_column << window_image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When platform is ubuntu' do
          it 'shows only ubuntu AMIs List' do
            knife_ec2_ami_list.config[:platform] = 'ubuntu'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            ubuntu_image = ec2_connection.describe_images.body['imagesSet'][1]
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << ubuntu_image["imageId"]
            output_column << ubuntu_image["name"].split(/\W+/).first
            output_column << ubuntu_image["architecture"]
            output_column << ubuntu_image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << ubuntu_image["name"].split(/\W+/).first
            output_column << ubuntu_image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When platform is fedora' do
          it 'shows only fedora AMIs List' do
            knife_ec2_ami_list.config[:platform] = 'fedora'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect(knife_ec2_ami_list).to receive(:validate!)
            fedora_image = ec2_connection.describe_images.body['imagesSet'].last
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << fedora_image["imageId"]
            output_column << fedora_image["name"].split(/\W+/).first
            output_column << fedora_image["architecture"]
            output_column << fedora_image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << fedora_image["name"].split(/\W+/).first
            output_column << fedora_image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When platform is invalid' do
          it 'raises error' do
            knife_ec2_ami_list.config[:platform] = 'xyz'
            knife_ec2_ami_list.config[:use_iam_profile] = true
            knife_ec2_ami_list.config[:owner] = true
            expect{ knife_ec2_ami_list.validate! }.to raise_error "Invalid platform: #{knife_ec2_ami_list.config[:platform]}. Allowed platforms are: windows, ubuntu, debian, centos, fedora, rhel, nginx, turnkey, jumpbox, coreos, cisco, amazon, nessus."
          end
        end
      end

      context 'when --search is passed' do
        before do
          allow(knife_ec2_ami_list.ui).to receive(:warn)
          allow(knife_ec2_ami_list).to receive(:custom_warnings!)
        end

        context 'When search key word is present in description' do
          it 'shows only AMIs List that have 14.04 in description' do
            knife_ec2_ami_list.config[:search] = '14.04'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            image = ec2_connection.describe_images.body['imagesSet'][2]
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << image["imageId"]
            output_column << image["name"].split(/\W+/).first
            output_column << image["architecture"]
            output_column << image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << image["name"].split(/\W+/).first
            output_column << image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When user pass platform and search keyword' do
          it 'shows only AMIs List that have 14.04 in description and platform is ubuntu' do
            knife_ec2_ami_list.config[:platform] = 'ubuntu'
            knife_ec2_ami_list.config[:search] = 'Quan'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            ubuntu_image = ec2_connection.describe_images.body['imagesSet'][1]
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << ubuntu_image["imageId"]
            output_column << ubuntu_image["name"].split(/\W+/).first
            output_column << ubuntu_image["architecture"]
            output_column << ubuntu_image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << ubuntu_image["name"].split(/\W+/).first
            output_column << ubuntu_image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When user pass owner, platform and search keyword' do
          it 'shows only AMIs List that owner microsoft platform windows and search keyword is winrm' do
            knife_ec2_ami_list.config[:owner] = 'microsoft'
            knife_ec2_ami_list.config[:platform] = 'windows'
            knife_ec2_ami_list.config[:search] = 'winrm'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            ubuntu_image = ec2_connection.describe_images.body['imagesSet'].first
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            output_column << ubuntu_image["imageId"]
            output_column << ubuntu_image["platform"]
            output_column << ubuntu_image["architecture"]
            output_column << ubuntu_image["blockDeviceMapping"].first["volumeSize"].to_s
            output_column << ubuntu_image["name"].split(/\W+/).first
            output_column << ubuntu_image["description"]
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end

        context 'When search key word is not present in description' do
          it 'Fetch no AMI' do
            knife_ec2_ami_list.config[:search] = 'Not present'
            allow(ec2_connection).to receive(:describe_images).and_return(@describe_images_format)
            expect(knife_ec2_ami_list).to receive(:validate!)
            output_column = ["AMI ID", "Platform", "Architecture", "Size", "Name", "Description"]
            output_column_count = output_column.length
            expect(knife_ec2_ami_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
            knife_ec2_ami_list.run
          end
        end
      end
    end
  end
