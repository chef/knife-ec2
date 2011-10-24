#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'bundler/setup'
require 'jeweler'
require 'yard'

require 'rspec/core/rake_task'

task :default => :spec

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'LICENSE', 'README.md', 'spec/tiny_server.rb']
end

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

Jeweler::Tasks.new do |gem|
    require "knife-ec2/version"
    gem.name = "knife-ec2"
    gem.version = Knife::Ec2::VERSION
    gem.email = ["Adam Jacob","Seth Chisamore"]
    gem.authors = ["adam@opscode.com","schisamo@opscode.com"]
    gem.homepage = "http://wiki.opscode.com/display/chef"
    gem.summary = "Amazon EC2 Support for Chef's Knife Command"
    gem.description = "This is the official Opscode Knife plugin for EC2. This plugin gives knife the ability to create, bootstrap, and manage EC2 instances."
end