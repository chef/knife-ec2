require 'fog'

class Chef
  class Knife
    class S3Source
      attr_accessor :url

      def body
        bucket_obj = fog.directories.get(bucket)
        bucket_obj.files.get(path).body
      end

      private

      def bucket
        URI(@url).host
      end

      def path
        URI(@url).path.sub(/^\//, '')
      end

      def fog
        @fog ||= Fog::Storage::AWS.new
      end
    end
  end
end
