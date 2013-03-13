$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef'
require 'chef/knife/ec2_server_create'
require 'chef/knife/ec2_instance_data'
require 'chef/knife/ec2_server_delete'
require 'chef/knife/ec2_server_list'
require 'chef/knife/ec2_security_group_list'
require 'chef/knife/ec2_security_group_create'
require 'chef/knife/ec2_security_group_rule_add'
