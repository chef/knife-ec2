#
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

class Chef
  class Knife
    class S3Source
      attr_accessor :url

      def self.fetch(url)
        source = Chef::Knife::S3Source.new
        source.url = url
        source.body
      end

      def body
        bucket_obj.files.get(path).body
      end

      private

      def bucket_obj
        @bucket_obj ||= fog.directories.get(bucket)
      end

      def bucket
        uri = URI(@url)
        if uri.scheme == "s3"
          URI(@url).host
        else
          URI(@url).path.split("/")[1]
        end
      end

      def path
        uri = URI(@url)
        if uri.scheme == "s3"
          URI(@url).path.sub(/^\//, "")
        else
          URI(@url).path.split(bucket).last.sub(/^\//, "")
        end
      end

      def fog
        require "fog/aws" # lazy load the fog library to speed up the knife run
        @fog ||= Fog::Storage::AWS.new(
          aws_access_key_id: Chef::Config[:knife][:aws_access_key_id],
          aws_secret_access_key: Chef::Config[:knife][:aws_secret_access_key]
        )
      end
    end
  end
end
