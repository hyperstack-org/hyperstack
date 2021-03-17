require_relative 'install_generator_base'
module Hyperstack
  class InstallGenerator < Rails::Generators::Base

    class_option 'skip-hotloader', type: :boolean
    class_option 'skip-webpack', type: :boolean
    class_option 'skip-hyper-model', type: :boolean
    class_option 'hotloader-only', type: :boolean
    class_option 'webpack-only', type: :boolean
    class_option 'hyper-model-only', type: :boolean

    def add_hotloader
      return if skip_hotloader?
      unless Hyperstack.imported? 'hyperstack/hotloader'
        inject_into_initializer(
          "Hyperstack.import 'hyperstack/hotloader', "\
          'client_only: true if Rails.env.development?'
        )
      end
      create_file 'Procfile', <<-TEXT
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
      TEXT
      gem_group :development do
        gem 'foreman'
      end
    end

    def install_webpack
      return super unless skip_webpack?

      inject_into_initializer(
        "Hyperstack.import 'react/react-source-browser' "\
        "# bring in hyperstack's copy of react, comment this out "\
        "if you bring it in from webpacker\n"
      )
    end

    def add_component
      # add_component AFTER webpack so component generator webpack check works
      if skip_adding_component?
        # normally this is handled by the hyper:component
        # generator, but if we are skipping it we will check it
        # now.
        insure_hyperstack_loader_installed
        check_javascript_link_directory
      else
        generate 'hyper:router App --add-route'
      end
    end

    def create_policies_directory
      return if skip_hyper_model?
      policy_file = Rails.root.join('app', 'policies', 'hyperstack', 'application_policy.rb')
      unless File.exist? policy_file
        create_file policy_file, <<-RUBY
  # #{policy_file}

  # Policies regulate access to your public models
  # The following policy will open up full access (but only in development)
  # The policy system is very flexible and powerful.  See the documentation
  # for complete details.
  module Hyperstack
    class ApplicationPolicy
      # Allow any session to connect:
      always_allow_connection
      # Send all attributes from all public models
      regulate_all_broadcasts { |policy| policy.send_all }
      # Allow all changes to models
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end unless Rails.env.production?
  end
        RUBY
      end
    end

    def move_and_update_application_record
      return if skip_hyper_model?
      rails_app_record_file = Rails.root.join('app', 'models', 'application_record.rb')
      hyper_app_record_file = Rails.root.join('app', 'hyperstack', 'models', 'application_record.rb')
      unless File.exist? hyper_app_record_file
        empty_directory Rails.root.join('app', 'hyperstack', 'models')
        `mv #{rails_app_record_file} #{hyper_app_record_file}`
        inject_into_file hyper_app_record_file, before: /^end/, verbose: false do
          "  # allow remote access to all scopes - i.e. you can count or get a list of ids\n"\
          "  # for any scope or relationship\n"\
          "  ApplicationRecord.regulate_scope :all unless Hyperstack.env.production?\n"
        end

#         create_file rails_app_record_file, <<-RUBY
# # #{rails_app_record_file}
# # the presence of this file prevents rails migrations from recreating application_record.rb
# # see https://github.com/rails/rails/issues/29407
#
# require 'models/application_record.rb'
#         RUBY
      end
    end

    def turn_on_transport
      inject_into_initializer <<-RUBY

# transport controls how push (websocket) communications are
# implemented.  The default is :none.
# Other possibilities are :action_cable, :pusher (see www.pusher.com)
# or :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # :pusher, :simple_poller or :none

      RUBY
    end

    def add_engine_route
      return if skip_hyper_model?
      route 'mount Hyperstack::Engine => \'/hyperstack\'  # this route should be first in the routes file so it always matches'
    end

    def report
      say "\n\n"
      unless skip_adding_component?
        say '🎢 Top Level App Component successfully installed at app/hyperstack/components/app.rb 🎢', :green
      end
      if !new_rails_app?
        say '🎢 Top Level App Component skipped, you can manually generate it later 🎢', :green
      end
      unless skip_webpack?
        say '📦 Webpack integrated with Hyperstack.  '\
            'Add javascript assets to app/javascript/packs/client_only.js and /client_and_server.js 📦', :green
      end
      unless skip_hyper_model?
        say '👩‍✈️ Basic development policy defined.  See app/policies/application_policy.rb 👨🏽‍✈️', :green
        say '💽 HyperModel installed. Move any Active Record models to the app/hyperstack/models to access them from the client 📀', :green
      end
      if File.exist?(init = Rails.root.join('config', 'initializers', 'hyperstack.rb'))
        say "☑️  Check #{init} for other configuration options. ☑️", :green
      end
      unless skip_hotloader?
        say '🚒 Hyperstack Hotloader installed - use bundle exec foreman start and visit localhost:5000 🚒', :green
      end

      say "\n\n"

      warnings.each { |warning| say "#{warning}", :yellow }
    end

    private

    def skip_adding_component?
      options['hotloader-only'] || options['webpack-only'] || options['hyper-model-only'] || !new_rails_app?
    end

    def skip_hotloader?
      options['skip-hotloader'] || options['webpack-only'] || options['hyper-model-only']
    end

    def skip_webpack?
      options['hotloader-only'] || options['skip-webpack'] || options['hyper-model-only']
    end

    def skip_hyper_model?
      options['hotloader-only'] || options['webpack-only'] || options['skip-hyper-model']
    end

    def new_rails_app?
      # check to see if there are any routes set up and remember it, cause we might add a route in the process
      @new_rails_app ||= begin
        route_file = Rails.root.join('config', 'routes.rb')
        count = File.foreach(route_file).inject(0) do |c, line|
          line = line.strip
          next c if line.empty?
          next c if line.start_with?('#')
          next c if line.start_with?('mount')
          c + 1
        end
        count <= 2
      end
    end
  end
end
