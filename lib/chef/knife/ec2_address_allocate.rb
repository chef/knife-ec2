#
# Author:: Alfred Rossi (<alfred@actionverb.com>)
# Copyright:: Copyright (c) 2012 Action Verb, LLC.
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
    class Ec2AddressAllocate < Knife

      include Knife::Ec2Base

      banner "knife ec2 address allocate (options)"

      def run
        $stdout.sync = true

        validate!

        msg_pair('Public IP', connection.allocate_address.body['publicIp'].to_s)

      end
    end
  end
end

