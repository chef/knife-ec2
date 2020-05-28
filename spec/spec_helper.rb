$:.unshift File.expand_path("../../lib", __FILE__)
require "chef"
require "chef/knife/ec2_server_create"
require "chef/knife/ec2_server_delete"
require "chef/knife/ec2_server_list"
require "chef/knife/ec2_ami_list"
require "chef/knife/ec2_flavor_list"

class UnexpectedSystemExit < RuntimeError
  def self.from(system_exit)
    new(system_exit.message).tap { |e| e.set_backtrace(system_exit.backtrace) }
  end
end

# Clear config between each example
# to avoid dependencies between examples
RSpec.configure do |c|
  c.raise_errors_for_deprecations!
  c.raise_on_warning = true
  c.filter_run_excluding exclude: true
  c.before(:each) do
    Chef::Config.reset
    Chef::Config[:knife] = {}
  end

  c.around(:example) do |ex|
    begin
      ex.run
    rescue SystemExit => e
      raise UnexpectedSystemExit.from(e)
    end
  end
end
