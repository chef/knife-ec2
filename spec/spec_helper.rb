$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/node'
require 'fog'
require 'chef/knife/ec2_server_create'
require 'chef/knife/bootstrap_windows_ssh'

class TestResource
  def initialize(*args)
    args.each do |arg|
      arg.each do |key, value|
        add_attribute = "class << self; attr_accessor :#{key}; end"
        eval(add_attribute)
        eval("@#{key} = value")
      end
    end
  end
end