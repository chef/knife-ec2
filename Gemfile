source 'https://rubygems.org'

gemspec

source "https://artifactory-internal.ps.chef.co/artifactory/api/gems/omnibus-gems-local" do
    gem "knife", ">= 19.0"
end

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
