
require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require File.expand_path('../boot', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(assets: %w(development test)))

require 'opal-rails'
require 'hyper-component'

module TestApp
  class Application < Rails::Application
    #config.action_cable.allowed_request_origins = [/http\:\/\/127\.0\.0\.1\:[0-9]*/]
    config.eager_load_paths += %W(#{config.root}/app/models/public)
    config.autoload_paths += %W(#{config.root}/app/models/public)
    config.assets.paths << ::Rails.root.join('app', 'models').to_s
    config.opal.method_missing = true
    config.opal.optimized_operators = true
    config.opal.arity_check = false
    config.opal.const_missing = true
    config.opal.dynamic_require_severity = :ignore
    config.opal.enable_specs = true
    config.opal.spec_location = 'spec-opal'
    config.hyperstack.auto_config = false

    config.assets.cache_store = :null_store

    config.react.server_renderer_options = {
      files: ['server_rendering.js']
    }
    config.react.server_renderer_directories = ['/app/assets/javascripts']
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    #config.active_record.raise_in_transactional_callbacks = true
  end
end
