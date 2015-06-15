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

require 'bundler'
Bundler::GemHelper.install_tasks

# require 'rubygems'
# require 'rake/gempackagetask'
require 'rdoc/task'

begin
  require 'sdoc'
  require 'rdoc/task'

  RDoc::Task.new do |rdoc|
    rdoc.title = 'Chef Ruby API Documentation'
    rdoc.main = 'README.rdoc'
    rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
    rdoc.template = 'direct' # lighter template
    rdoc.rdoc_files.include('README.rdoc', 'LICENSE', 'spec/tiny_server.rb', 'lib/**/*.rb')
    rdoc.rdoc_dir = 'rdoc'
  end
rescue LoadError
  puts 'sdoc is not available. (sudo) gem install sdoc to generate rdoc documentation.'
end

begin
  require 'rspec/core/rake_task'

  task :default => :spec

  desc 'Run all specs in spec directory'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
