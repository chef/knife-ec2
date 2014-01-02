$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/node'

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
