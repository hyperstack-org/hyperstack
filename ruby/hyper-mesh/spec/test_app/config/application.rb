require "rails/all"
require File.expand_path('../boot', __FILE__)

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(assets: %w(development test)))

module TestApp
  class Application < Rails::Application
    config.assets.debug = false
  end
end
