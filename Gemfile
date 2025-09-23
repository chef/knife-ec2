source 'https://rubygems.org'

gemspec

gem 'knife', git: 'https://github.com/chef/knife.git', branch: 'main'

group :debug do
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'abbrev'
  gem 'chefstyle'
  gem 'chef-zero', '~> 14' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.6')
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'syslog'
end

group :docs do
  gem 'github-markup'
  gem 'redcarpet'
  gem 'yard'
end
