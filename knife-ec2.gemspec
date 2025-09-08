$LOAD_PATH.push File.expand_path("lib", __dir__)
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
  s.required_ruby_version = ">= 3.1"

  s.add_dependency "knife", "~> 18.0"
  s.add_dependency "aws-sdk-s3", "~> 1.43"
  s.add_dependency "aws-sdk-ec2", "~> 1.95"

  # These gems were removed from Ruby standard library from version 3.4
  # See: https://stdgems.org/new-in/3.4
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
    s.add_dependency "abbrev", "~> 0.1"
    s.add_dependency "syslog", "~> 0.3"
  end

  s.require_paths = ["lib"]
end
