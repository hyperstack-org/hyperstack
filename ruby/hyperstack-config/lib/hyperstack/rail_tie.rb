module Hyperstack

  class Engine < ::Rails::Engine
  end

  define_setting :add_hyperstack_paths, true

  define_setting :prerendering_files, ['hyperstack-prerender-loader.js']

  class Railtie < ::Rails::Railtie

    class Options < ActiveSupport::OrderedOptions
      def delete_first(a, e)
        a.delete_at(a.index(e) || a.length)
      end

      def auto_config=(on)
        Rails.configuration.tap do |config|
          if [:on, 'on', true].include?(on)
            
            config.filter_parameters << :hyperstack_secured_json

            config.eager_load_paths += %W(#{config.root}/app/hyperstack/models)
            config.eager_load_paths += %W(#{config.root}/app/hyperstack/models/concerns)
            config.eager_load_paths += %W(#{config.root}/app/hyperstack/operations)
            config.eager_load_paths += %W(#{config.root}/app/hyperstack/shared)

            # rails will add everything immediately below app to eager and auto load, so we need to remove it
            delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"

            unless Rails.env.production?
              config.autoload_paths += %W(#{config.root}/app/hyperstack/models)
              config.autoload_paths += %W(#{config.root}/app/hyperstack/models/concerns)
              config.autoload_paths += %W(#{config.root}/app/hyperstack/operations)
              config.autoload_paths += %W(#{config.root}/app/hyperstack/shared)

              # config.eager_load_paths += %W(#{config.root}/app/hyperstack/stores)
              # config.autoload_paths += %W(#{config.root}/app/hyperstack/stores)
              delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
            end
            # possible alternative way in conjunction with below
            # %w[stores operations models components].each do |hp|
            #   hps = ::Rails.root.join('app', 'hyperstack', hp).to_s
            #   config.assets.paths.delete(hps)
            #   config.assets.paths.unshift(hps)
            # end
            config.assets.paths.unshift ::Rails.root.join('app', 'hyperstack').to_s
            if Rails.const_defined? 'Hyperstack::Console'
              config.assets.precompile += %w( hyper-console-client.css )
              config.assets.precompile += %w( hyper-console-client.min.js )
              config.assets.precompile += %w( action_cable.js ) if Rails.const_defined? 'ActionCable'
            end
         else
            delete_first config.eager_load_paths, "#{config.root}/app/hyperstack/models"
            delete_first config.eager_load_paths, "#{config.root}/app/hyperstack/models/concerns"
            delete_first config.autoload_paths, "#{config.root}/app/hyperstack/models"
            delete_first config.autoload_paths, "#{config.root}/app/hyperstack/models/concerns"
            # delete_first config.eager_load_paths, "#{config.root}/app/hyperstack/stores"
            # delete_first config.autoload_paths, "#{config.root}/app/hyperstack/stores"
            delete_first config.eager_load_paths, "#{config.root}/app/hyperstack/operations"
            delete_first config.autoload_paths, "#{config.root}/app/hyperstack/operations"
            delete_first config.eager_load_paths, "#{config.root}/app/hyperstack/shared"
            delete_first config.autoload_paths, "#{config.root}/app/hyperstack/shared"


            delete_first config.assets.paths, ::Rails.root.join('app', 'hyperstack').to_s
          end
        end
        super
      end
    end

    # note in case of problems with eager load paths have a look at
    # https://github.com/opal/opal-rails/blob/master/lib/opal/rails/engine.rb
    config.hyperstack = Options.new

    config.before_configuration do |app|
      config.hyperstack.auto_config = true
    end

    config.after_initialize do |app|
      next unless [:on, 'on', true].include?(config.hyperstack.auto_config)
      # possible alternative way
      # %w[stores operations models components].each do |hp|
      #   Hyperstack.import_tree('hyperstack/' + hp)
      # end
      Hyperstack.import_tree('hyperstack')
      if config.respond_to?(:react)
        if (opts = config.react.server_renderer_options)
          opts.merge!(files: Hyperstack.prerendering_files)
        else
          config.react.server_renderer_options = {files: Hyperstack.prerendering_files}
        end
      end
    end
  end
end
