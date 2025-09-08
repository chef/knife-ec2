source "https://rubygems.org"

gemspec


group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
end

group :test do
  gem "syslog"
  gem "abbrev"
  gem "chefstyle"
  gem "rake"
  gem "rspec", "~> 3.0"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
  end
end

group :docs do
  gem "github-markup"
  gem "redcarpet"
  gem "yard"
end
