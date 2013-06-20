#
# Author:: Denis Corol (<dcorol@gmail.com>)
# Copyright:: Copyright (c) 2013
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

require 'chef/knife/ec2_base'

class Chef
  class Knife
    class Ec2SgList < Knife

      include Knife::Ec2Base

      banner "knife ec2 sg list (options)"

      def run
        $stdout.sync = true

        validate!

        sg_list = [
          ui.color('Name', :bold),
          ui.color('Description', :bold)
        ]

       connection.security_groups.all.each do |sg|
         sg_list << sg.name.to_s
         sg_list << sg.description.to_s
       end

       puts ui.list(sg_list, :uneven_columns_across, 2)

      end
    end
  end
end


