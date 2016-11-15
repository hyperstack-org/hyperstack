require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ActionCable
  class Application < Rails::Application
    config.eager_load_paths += %W(#{config.root}/app/models/public)
    config.eager_load_paths += %W(#{config.root}/app/views/components)
    config.autoload_paths += %W(#{config.root}/app/models/public)
    config.autoload_paths += %W(#{config.root}/app/views/components)
    config.assets.paths << ::Rails.root.join('app', 'models').to_s
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
