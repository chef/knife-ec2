
require 'erb'

# Class to create an binding object with dynamically added instance variables.
module ERBHelpers
  # Usage: ERB.new("Hello <%= name %>!!").result(ERBParams.new(:name => "Ruby World").get_binding)
  class ERBParams
    def initialize(*args)
      args.each do |arg|
        arg.each do |key, value|
          instance_variable_set("@#{key}", value)
          # Add attribute accessor
          eval("class << self; attr_accessor :#{key}; end")
        end
      end
    end
    def get_binding
      binding
    end
  end

  # Usage: ERBCompiler.run("Hello <%= name %>!!", {:name => "Ruby World"})
  class ERBCompiler
    def self.run(template, attributes)
      begin
        ERB.new(template).result(ERBParams.new(attributes).get_binding)
      rescue NameError
        puts "\n** Check whether all necessary ERB template substitution params are defined in attributes argument. #{attributes} \n\n"
        raise
      end
    end
  end
end