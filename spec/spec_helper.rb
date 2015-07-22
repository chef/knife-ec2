$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef'
require 'chef/knife/winrm_base'
require 'chef/knife/ec2_server_create'
require 'chef/knife/ec2_server_delete'
require 'chef/knife/ec2_server_list'

# Clear config between each example
# to avoid dependencies between examples
RSpec.configure do |c|
  c.raise_errors_for_deprecations!
  c.filter_run_excluding :exclude => true
  c.before(:each) do
    Chef::Config.reset
    Chef::Config[:knife] ={}
  end
end

