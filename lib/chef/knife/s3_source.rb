require 'fog'

class Chef
  class Knife
    class S3Source
      attr_accessor :url

      def content
        bucket = fog.directories.get(bucket)
        bucket.files.get(path)
      end

      private

      def bucket
        URI(s3_url).host
      end

      def path
        URI(s3_url).path.sub(/^\//, '')
      end

      def fog
        @fog ||= Fog::Storage::AWS.new
      end
    end
  end
end
