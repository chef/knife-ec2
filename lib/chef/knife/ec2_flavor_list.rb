#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2012-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/knife/ec2_base"

class Chef
  class Knife
    class Ec2FlavorList < Knife

      include Knife::Ec2Base

      banner "knife ec2 flavor list (options) [DEPRECATED]"

      def run
        ui.error("knife ec2 flavor list has been deprecated as this functionality is not provided by the AWS API the previous implementatin relied upon hardcoded values that were often incorrect. For an up to date list of instance types see https://www.ec2instances.info/")
        exit 1
      end
    end
  end
end
