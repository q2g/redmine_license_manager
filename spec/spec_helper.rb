ENV['RAILS_ENV'] ||= 'test'
# Use SimpleCov
require 'simplecov'
SimpleCov.start do
   add_filter 'spec/'
end

# Loading rails environment
require File.expand_path("../../../../config/environment", __FILE__)
require 'rspec/rails'

# Force using test db connection for test env
db_config = YAML.load(File.open("#{Rails.root}/config/database.yml").read)['test']
ActiveRecord::Base.establish_connection(db_config)

# Loading relevant Files from lib/app
# TODO: update with required paths - Require files, add controllers and models here
require File.expand_path("../../lib/redmine_license_manager.rb", __FILE__)

Rails.application.config.paths['app/views'].unshift(File.expand_path("../../app/views", __FILE__))

# Extend test suite
require "pry"
require "factory_girl"
Dir.glob(File.expand_path("../support/*.rb", __FILE__)).each {|factory_rb| require factory_rb }


Rails.application.config.after_initialize do
  Rails.application.config.i18n.load_path += Dir[File.expand_path("../config/locales/*.yml", __FILE__)]

  # TODO: If core clas extensions are required, they should be loaded here
end

# include and load factories
RSpec.configure { |config| config.include FactoryGirl::Syntax::Methods }
Dir.glob(File.expand_path("../factories/*.rb", __FILE__)).each {|factory_rb| require factory_rb }

require 'capybara/rails'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end
end
