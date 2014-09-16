class Chef
  class Knife
    module Core
      def validation_key
        require 'byebug'
        byebug
        begin
          if knife_config[:validation_key]
            IO.read(File.expand_path(knife_config[:validation_key]))
          else
            IO.read(File.expand_path(@chef_config[:validation_key]))
          end
        rescue Exception => e
          puts e.backtrace
          raise e
        end
      end
    end
  end
end
