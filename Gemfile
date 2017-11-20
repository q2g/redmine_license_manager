source 'https://rubygems.org'

gem 'colorize'

# these are required in order to run the specs with 'rspec-rails' in EasyRedmine
# use RAILS_ENV=test in order to run the specs via 'rspec' command
# please note: the gems need to be exactly the same versions as given in your host redmine application Gemfile
if ENV['RAILS_ENV'] == 'test'
  gem 'rails'
  gem 'activesupport'
  gem 'actionpack-xml_parser'
  gem 'mysql2', '~> 0.3.11'
  gem 'rack-openid'
  gem 'protected_attributes'
  gem 'request_store', '1.0.5'
  gem "factory_bot_rails"
end

group :development, :test do
  gem "pry"
end







