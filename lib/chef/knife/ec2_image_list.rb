require 'chef/knife/ec2_base'

class Chef
  class Knife
    class Ec2ImageList < Knife

      include Knife::Ec2Base

      banner "knife ec2 image list (options)"

      def run
        $stdout.sync = true

        validate!

        image_list = [
          ui.color('Image', :bold),
          ui.color('Name', :bold),
          ui.color('Source', :bold),
        ]
        connection.images.all('Owner'=>'self').each do |image|
            image_list << image.id.to_s
            image_list << image.name.to_s
            image_list << image.description.to_s
        end
        puts ui.list(image_list, :uneven_columns_across, 3)
      end
    end
  end
end
