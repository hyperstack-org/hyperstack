require "rails/all"
require File.expand_path('../boot', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(assets: %w(development test)))

require 'opal-rails'
require 'hyper-react'

module TestApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.eager_load_paths += %W(#{config.root}/app/models/public)
    config.autoload_paths += %W(#{config.root}/app/models/public)
    config.assets.paths << ::Rails.root.join('app', 'models').to_s
    # config.opal.arity_check = false
  end
end
