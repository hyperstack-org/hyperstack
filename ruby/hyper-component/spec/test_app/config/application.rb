
require 'rails/all'
require File.expand_path('../boot', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(assets: %w(development test)))
require 'jquery-rails'
require 'opal'
require 'opal-jquery'
require 'opal-browser'
require 'opal-rails'
require 'react-rails'
require 'hyper-store'
require 'hyper-react'
require 'hyper-spec'

module TestApp
  class Application < Rails::Application
    config.opal.method_missing = true
    config.opal.optimized_operators = true
    config.opal.arity_check = false
    config.opal.const_missing = true
    config.opal.dynamic_require_severity = :ignore
    config.opal.enable_specs = true
    config.opal.spec_location = 'spec-opal'
    config.hyperloop.auto_config = false

    config.assets.cache_store = :null_store

    config.react.server_renderer_options = {
      files: ["server_rendering.js"]
    }
    config.react.server_renderer_directories = ["/app/assets/javascripts"]

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end


