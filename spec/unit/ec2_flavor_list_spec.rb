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
require 'chef/knife/ec2_flavor_list'

describe Chef::Knife::Ec2FlavorList do

  describe '#run' do
    let(:knife_flavor_list) { Chef::Knife::Ec2FlavorList.new }
    let(:ec2_connection) { double(Fog::Compute::AWS) }
    before do
      allow(knife_flavor_list).to receive(:connection).and_return(ec2_connection)
    end

    it 'invokes validate!' do
      ec2_flavors = double(:sort_by => [])

      allow(ec2_connection).to receive(:flavors).and_return(ec2_flavors)
      allow(knife_flavor_list.ui).to receive(:warn)
      expect(knife_flavor_list).to receive(:validate!)
      knife_flavor_list.run
    end

    before do
      @flavor1 = double("flavor1", :name => "Micro Instance", :id => "t1.micro", :bits => "0", :cores => "2", :disk => "0", :ram => "613", :ebs_optimized_available => "false", :instance_store_volumes => "0")
      @flavor2 = double("flavor2", :name => "Micro Instance", :id => "t2.micro", :bits => "64", :cores => "1", :disk => "0", :ram => "1024", :ebs_optimized_available => "false", :instance_store_volumes => "0")
      @flavor3 = double("flavor3", :name => "Micro Instance", :id => "t2.small", :bits => "64", :cores => "1", :disk => "0", :ram => "2048", :ebs_optimized_available => "false", :instance_store_volumes => "0")

      allow(ec2_connection).to receive(:flavors).and_return([@flavor1, @flavor2, @flavor3])
    end


    context '--format option' do
      context 'when format=summary' do
        before do
          knife_flavor_list.config[:format] = 'summary'
          allow(knife_flavor_list.ui).to receive(:warn)
        end

        it 'shows the output in summary format' do
          output_column = ["ID", "Name", "Architecture", "RAM", "Disk", "Cores"]
          output_column_count = output_column.length
	  allow(ec2_connection).to receive(:flavors).and_return([])
          allow(knife_flavor_list).to receive(:validate!)
          expect(knife_flavor_list.ui).to receive(:list).with(output_column,:columns_across, output_column_count)
          knife_flavor_list.run
        end
      end

      context 'when format=json' do
        before do
          knife_flavor_list.config[:format] = 'json'
          allow(knife_flavor_list.ui).to receive(:warn)
        end

        it 'shows the output in json format' do
          allow(ec2_connection).to receive(:flavors).and_return([])
          allow(knife_flavor_list).to receive(:validate!)
          allow(knife_flavor_list).to receive(:format_for_display)
          expect(knife_flavor_list).to receive(:output)
          knife_flavor_list.run
        end
      end

    end

end
end
