# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'knife-ec2/version'

Gem::Specification.new do |s|
  s.name         = 'knife-ec2'
  s.version      = Knife::Ec2::VERSION
  s.authors      = ['Adam Jacob', 'Seth Chisamore']
  s.email        = ['adam@opscode.com', 'schisamo@opscode.com']
  s.homepage     = 'https://github.com/opscode/knife-ec2'
  s.summary      = "EC2 Support for Chef's Knife Command"
  s.description  = s.summary
  s.license      = 'Apache-2.0'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency 'fog',           '~> 1.29.0'
  s.add_dependency 'knife-windows', '~> 1.0'

  s.add_development_dependency 'chef',  '~> 12.0', '>= 12.2.1'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rake',  '~> 10.1'
  s.add_development_dependency 'sdoc',  '~> 0.3'

  s.require_paths = ['lib']
end
