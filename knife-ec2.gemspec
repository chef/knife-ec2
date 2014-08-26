# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-ec2/version"

Gem::Specification.new do |s|
  s.name = "knife-ec2"
  s.version = Knife::Ec2::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE" ]
  s.authors = ["Clogeny"]
  s.email = [""]
  s.homepage = "https://github.com/opscode/knife-ec2"
  s.summary = %q{Ec2 Compute Support for Chef's Knife Command}
  s.description = %q{Ec2 Compute Support for Chef's Knife Command using knife-cloud gem}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "fog", ">= 1.23.0"
  s.add_dependency "knife-cloud"
  s.add_development_dependency "chef", ">= 0.10.10"

  %w(rspec-core rspec-expectations rspec-mocks rspec_junit_formatter).each { |gem| s.add_development_dependency gem }
end
