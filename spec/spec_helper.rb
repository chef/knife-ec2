$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/node'
require 'fog'
require 'chef/knife/ec2_server_create'
require 'chef/knife/bootstrap_windows_ssh'
require 'resource_spec_helper'