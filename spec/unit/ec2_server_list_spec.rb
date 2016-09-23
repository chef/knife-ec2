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

describe Chef::Knife::Ec2ServerList do

  describe '#run' do
    let(:knife_ec2_list) { Chef::Knife::Ec2ServerList.new }
    let(:ec2_connection) { double(Fog::Compute::AWS) }
    before do
      allow(knife_ec2_list).to receive(:connection).and_return(ec2_connection)
    end

    it 'invokes validate!' do
      ec2_servers = double()
      allow(ec2_connection).to receive(:servers).and_return(ec2_servers)
      allow(knife_ec2_list.ui).to receive(:warn)
      expect(knife_ec2_list).to receive(:validate!)
      knife_ec2_list.run
    end

    context 'when region is not specified' do
      it 'shows warning that default region will be will be used' do
        knife_ec2_list.config.delete(:region)
        Chef::Config[:knife].delete(:region)
        ec2_servers = double()
        allow(ec2_connection).to receive(:servers).and_return(ec2_servers)
        allow(knife_ec2_list).to receive(:validate!)
        expect(knife_ec2_list.ui).to receive(:warn).with("No region was specified in knife.rb or as an argument. The default region, us-east-1, will be used:")
        knife_ec2_list.run
      end
    end

    context '--format option' do
      context 'when format=summary' do
        before do
          knife_ec2_list.config[:format] = 'summary'
          allow(knife_ec2_list.ui).to receive(:warn)
        end

        it 'shows the output without Tags and Availability Zone in summary format' do
          output_column = ["Instance ID", "Public IP", "Private IP", "Flavor",
            "Image", "SSH Key", "Security Groups", "IAM Profile", "State"]
          output_column_count = output_column.length
          allow(ec2_connection).to receive(:servers).and_return([])
          allow(knife_ec2_list).to receive(:validate!)
          expect(knife_ec2_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
          knife_ec2_list.run
        end
      end

      context 'when format=json' do
        before do
          knife_ec2_list.config[:format] = 'json'
          allow(knife_ec2_list.ui).to receive(:warn)
        end

        it 'shows the output without Tags and Availability Zone in summary format' do
          allow(ec2_connection).to receive(:servers).and_return([])
          allow(knife_ec2_list).to receive(:validate!)
          allow(knife_ec2_list).to receive(:format_for_display)
          expect(knife_ec2_list).to receive(:output)
          knife_ec2_list.run
        end
      end
    end

    context 'when --tags option is passed' do
      before do
        knife_ec2_list.config[:format] = 'summary'
        allow(knife_ec2_list.ui).to receive(:warn)
        allow(ec2_connection).to receive(:servers).and_return([])
        allow(knife_ec2_list).to receive(:validate!)
      end

      context 'when single tag is passed' do
        it 'shows single tag field in the output' do
          knife_ec2_list.config[:tags] = 'tag1'
          output_column = ["Instance ID", "Public IP", "Private IP", "Flavor",
            "Image", "SSH Key", "Security Groups", "Tag:tag1", "IAM Profile", "State"]
          output_column_count = output_column.length
          expect(knife_ec2_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
          knife_ec2_list.run
        end
      end

      context 'when multiple tags are passed' do
        it 'shows multiple tags fields in the output' do
          knife_ec2_list.config[:tags] = 'tag1,tag2'
          output_column = ["Instance ID", "Public IP", "Private IP", "Flavor",
            "Image", "SSH Key", "Security Groups", "Tag:tag1", "Tag:tag2", "IAM Profile", "State"]
          output_column_count = output_column.length
          expect(knife_ec2_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
          knife_ec2_list.run
        end
      end
    end

    context 'when --availability-zone is passed' do
      before do
        knife_ec2_list.config[:format] = 'summary'
        allow(knife_ec2_list.ui).to receive(:warn)
        allow(ec2_connection).to receive(:servers).and_return([])
        allow(knife_ec2_list).to receive(:validate!)
      end

      it 'shows the availability zones in the output' do
        knife_ec2_list.config[:az] = true
        output_column = ["Instance ID", "Public IP", "Private IP", "Flavor", "AZ",
            "Image", "SSH Key", "Security Groups", "IAM Profile", "State"]
        output_column_count = output_column.length
        expect(knife_ec2_list.ui).to receive(:list).with(output_column,:uneven_columns_across, output_column_count)
        knife_ec2_list.run
      end
    end
  end
end
