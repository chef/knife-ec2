require 'fog'

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
        URI(@url).path.split("/")[1]
      end

      def path
        URI(@url).path.split(bucket).last.sub(/^\//, '')
      end

      def fog
        @fog ||= Fog::Storage::AWS.new(
          aws_access_key_id: Chef::Config[:knife][:aws_access_key_id],
          aws_secret_access_key: Chef::Config[:knife][:aws_secret_access_key]
        )
      end
    end
  end
end