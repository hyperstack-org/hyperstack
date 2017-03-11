module Hyperloop
  define_setting :add_hyperloop_paths, true
  class Railtie < ::Rails::Railtie

    class Options < ActiveSupport::OrderedOptions
      def delete_first(a, e)
        a.delete_at(a.index(e) || a.length)
      end
      def add_paths=(x)
        Rails.configuration.tap do |config|
          if x
            config.eager_load_paths += %W(#{config.root}/app/hyperloop/models)
            config.autoload_paths += %W(#{config.root}/app/hyperloop/models)
            # config.eager_load_paths += %W(#{config.root}/app/hyperloop/stores)
            # config.autoload_paths += %W(#{config.root}/app/hyperloop/stores)
            config.eager_load_paths += %W(#{config.root}/app/hyperloop/operations)
            config.autoload_paths += %W(#{config.root}/app/hyperloop/operations)

            config.assets.paths.unshift ::Rails.root.join('app', 'hyperloop').to_s
            config.eager_load_paths += %W(#{config.root}/app/models/public)
            config.autoload_paths += %W(#{config.root}/app/models/public)
            config.assets.paths.unshift ::Rails.root.join('app', 'models').to_s
         else
            delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/models"
            delete_first config.autoload_paths, "#{config.root}/app/hyperloop/models"
            # delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/stores"
            # delete_first config.autoload_paths, "#{config.root}/app/hyperloop/stores"
            delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/operations"
            delete_first config.autoload_paths, "#{config.root}/app/hyperloop/operations"

            delete_first config.assets.paths, ::Rails.root.join('app', 'hyperloop').to_s
            delete_first config.eager_load_paths, %W(#{config.root}/app/models/public)
            delete_first config.autoload_paths, %W(#{config.root}/app/models/public)
            delete_first config.assets.paths, ::Rails.root.join('app', 'models').to_s
          end
        end
        super
      end
    end

    def add_hyperloop_directories(config)
      return if config.hyperloop.key?(:add_directories) && !config.hyperloop.add_directories
      Hyperloop.require_tree('views/components')
      Hyperloop.require_tree('hyperloop')
      Hyperloop.require_gem 'opal-jquery', override_with: :opal_jquery, client_only: true # move to hyper-component once things are working
    end

    # note in case of problems with eager load paths have a look at
    # https://github.com/opal/opal-rails/blob/master/lib/opal/rails/engine.rb
    config.hyperloop = Options.new

    config.before_configuration do |app|
      config.hyperloop.add_paths = true
    end
    config.after_initialize do |app|
      add_hyperloop_directories(app.config)
    end
  end
end
