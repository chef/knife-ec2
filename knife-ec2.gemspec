# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-ec2/version"

Gem::Specification.new do |s|
  s.name        = "knife-ec2"
  s.version     = Knife::Ec2::VERSION
  s.has_rdoc = true
  s.authors     = ["Adam Jacob","Seth Chisamore"]
  s.email       = ["adam@opscode.com","schisamo@opscode.com"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Amazon EC2 Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog", "~> 0.8.2"
  s.require_paths = ["lib"]

end
