require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ChatApp
  class Application < Rails::Application
    #ChatApp::Application.config.cache_store = :file_store, Rails.root.join('tmp', 'cache_store')
  end
end
