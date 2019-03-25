require_relative 'boot'

#require 'active_model'
# require "active_model/attribute_methods"
# require "active_model/errors"
# require 'active_model/callbacks'
# require 'active_model/naming'
# require 'active_model/translation'
# require 'active_model/forbidden_attributes_protection'
#
# require 'active_model/attribute_assignment'
# require 'active_model/validator'
#
# require 'active_model/validations'
# require 'active_model/conversion'
# require 'active_model/dirty'
# require 'active_model/secure_password'
# require 'active_model/serialization'
# require 'active_model/serializers/json'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TempLegacyTest
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
