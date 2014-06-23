#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
require 'chef/knife/ec2_volume_base'
require 'chef/knife/winrm_base'

class Chef
  class Knife
    class Ec2VolumeCreate < Knife

      include Knife::Ec2Base
      include Knife::Ec2VolumeBase
      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife ec2 volume create (options)"

      attr_reader :volumes

      def run
        $stdout.sync = true

        validate!
        create_volumes!

      end



      def validate!
        super([:aws_access_key_id, :aws_secret_access_key, :availability_zone, :volume_size])
      end
    end
  end
end
