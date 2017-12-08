module Hyperloop
  define_setting :add_hyperloop_paths, true
  
  define_setting :prerendering_files, ['hyperloop-prerender-loader.js']

  class Railtie < ::Rails::Railtie

    class Options < ActiveSupport::OrderedOptions
      def delete_first(a, e)
        a.delete_at(a.index(e) || a.length)
      end

      def auto_config=(on)
        Rails.configuration.tap do |config|
          if [:on, 'on', true].include?(on)
            config.eager_load_paths += %W(#{config.root}/app/hyperloop/models)
            config.eager_load_paths += %W(#{config.root}/app/hyperloop/operations)
            # rails will add everything immediately below app to eager and auto load, so we need to remove it
            delete_first config.eager_load_paths, "#{config.root}/app/hyperloop"

            unless Rails.env.production?
              config.autoload_paths += %W(#{config.root}/app/hyperloop/models)
              # config.eager_load_paths += %W(#{config.root}/app/hyperloop/stores)
              # config.autoload_paths += %W(#{config.root}/app/hyperloop/stores)
              
              config.autoload_paths += %W(#{config.root}/app/hyperloop/operations)
              delete_first config.autoload_paths, "#{config.root}/app/hyperloop"
            end

            config.assets.paths.unshift ::Rails.root.join('app', 'hyperloop').to_s
         else
            delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/models"
            delete_first config.autoload_paths, "#{config.root}/app/hyperloop/models"
            # delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/stores"
            # delete_first config.autoload_paths, "#{config.root}/app/hyperloop/stores"
            delete_first config.eager_load_paths, "#{config.root}/app/hyperloop/operations"
            delete_first config.autoload_paths, "#{config.root}/app/hyperloop/operations"

            delete_first config.assets.paths, ::Rails.root.join('app', 'hyperloop').to_s
          end
        end
        super
      end
    end

    # note in case of problems with eager load paths have a look at
    # https://github.com/opal/opal-rails/blob/master/lib/opal/rails/engine.rb
    config.hyperloop = Options.new

    config.before_configuration do |app|
      config.hyperloop.auto_config = true
    end

    config.after_initialize do |app|
      next unless [:on, 'on', true].include?(config.hyperloop.auto_config)
      Hyperloop.import_tree('hyperloop')
      if config.respond_to?(:react)
        if (opts = config.react.server_renderer_options)
          opts.merge!(files: Hyperloop.prerendering_files)
        else
          config.react.server_renderer_options = {files: Hyperloop.prerendering_files}
        end
      end
    end
  end
end
