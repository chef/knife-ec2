$:.unshift File.expand_path('../../lib', __FILE__)
require 'fog/aws'
require 'chef'
require 'chef/knife/ec2_server_create'
require 'chef/knife/ec2_instance_data'
require 'chef/knife/ec2_server_delete'
require 'chef/knife/ec2_server_list'

require 'stringio'

RSpec.configure do |config|
  def capture(*streams)
    streams.map! { |stream| stream.to_s }
    begin
      result = StringIO.new
      streams.each { |stream| eval "$#{stream} = result" }
      yield
    ensure
      streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
    end
    result.string
  end
end