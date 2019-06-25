# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "knife-ec2/version"

Gem::Specification.new do |s|
  s.name         = "knife-ec2"
  s.version      = Knife::Ec2::VERSION
  s.authors      = ["Chef Software, Inc."]
  s.email        = ["info@chef.io"]
  s.homepage     = "https://github.com/chef/knife-ec2"
  s.summary      = "Amazon EC2 Support for Chef's Knife Command"
  s.description  = s.summary
  s.license      = "Apache-2.0"

  s.files        = %w{LICENSE} + Dir.glob("lib/**/*")
  s.required_ruby_version = ">= 2.5"

  s.add_dependency "chef", ">= 15.1"
  s.add_dependency "aws-sdk-s3", "~> 1.43"
  s.add_dependency "aws-sdk-ec2", "~> 1.95"

  s.require_paths = ["lib"]
end
