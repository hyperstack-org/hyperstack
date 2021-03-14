require_relative 'install_generator_base'
module Hyperstack
  class InstallGenerator < Rails::Generators::Base

    class_option 'skip-hotloader', type: :boolean
    class_option 'skip-webpack', type: :boolean
    class_option 'skip-hyper-model', type: :boolean
    class_option 'hotloader-only', type: :boolean
    class_option 'webpack-only', type: :boolean
    class_option 'hyper-model-only', type: :boolean

    # def add_clexer
    #   gem 'c_lexer'
    #   Bundler.with_clean_env do
    #     run 'bundle update'
    #   end
    # end

    def add_component
      if skip_adding_component?
        # normally this is handled by the hyper:component
        # generator, but if we are skipping it we will check it
        # now.
        insure_hyperstack_loader_installed
      else
        generate 'hyper:router App --add-route'
      end
    end

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

    def insure_yarn_loaded
      return if skip_webpack?
      begin
        yarn_version = `yarn --version`
        raise Errno::ENOENT if yarn_version.blank?
      rescue Errno::ENOENT
        raise Thor::Error.new("please insure nodejs is installed and the yarn command is available if using webpacker")
      end
    end

    def add_webpacker_manifests
      return if skip_webpack?
      create_file 'app/javascript/packs/client_and_server.js', <<-JAVASCRIPT
//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                         // react-js library
createReactClass = require('create-react-class'); // backwards compatibility with ECMA5
History = require('history');                     // react-router history library
ReactRouter = require('react-router');            // react-router js library
ReactRouterDOM = require('react-router-dom');     // react-router DOM interface
ReactRailsUJS = require('react_ujs');             // interface to react-rails
// to add additional NPM packages run `yarn add package-name@version`
// then add the require here.
      JAVASCRIPT
      create_file 'app/javascript/packs/client_only.js', <<-JAVASCRIPT
//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
ReactDOM = require('react-dom');               // react-js client side code
jQuery = require('jquery');                    // remove if you don't need jQuery
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
      JAVASCRIPT
      append_file 'config/initializers/assets.rb' do
        <<-RUBY
Rails.application.config.assets.paths << Rails.root.join('public', 'packs', 'js').to_s
        RUBY
      end
      inject_into_file 'config/environments/test.rb', before: /^end/ do
        <<-RUBY

  # added by hyperstack installer
  config.assets.paths << Rails.root.join('public', 'packs-test', 'js').to_s
        RUBY
      end
    end

    def add_webpacks
      return if skip_webpack?

      yarn 'react', '16'
      yarn 'react-dom', '16'
      yarn 'react-router', '^5.0.0'
      yarn 'react-router-dom', '^5.0.0'
      yarn 'react_ujs', '^2.5.0'
      yarn 'jquery', '^3.4.1'
      yarn 'create-react-class'
    end

    def cancel_react_source_import
      inject_into_initializer(
        if skip_webpack?
          "Hyperstack.import 'react/react-source-browser' "\
          "# bring in hyperstack's copy of react, comment this out "\
          'if you bring it in from webpacker'
        else
          "# Hyperstack.import 'react/react-source-browser' "\
          '# uncomment this line if you want hyperstack to use its copy of react'
        end
      )
    end

    def install_webpacker
      return if skip_webpack?
      gem 'webpacker'
      Bundler.with_clean_env do
        run 'bundle install'
      end
      `spring stop`
      Dir.chdir(Rails.root.join.to_s) { run 'bundle exec rails webpacker:install' }
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
      # allow remote access to all scopes - i.e. you can count or get a list of ids
      # for any scope or relationship
      ApplicationRecord.regulate_scope :all
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
        create_file rails_app_record_file, <<-RUBY
# #{rails_app_record_file}
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

require 'models/application_record.rb'
        RUBY
      end
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

    def inject_into_initializer(s)
      file_name = Rails.root.join('config', 'initializers', 'hyperstack.rb')
      if File.exist?(file_name)
        prepend_to_file(file_name) { "#{s}\n" }
      else
        create_file file_name, <<-RUBY
#{s}
# set the component base class

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on

# transport controls how push (websocket) communications are
# implemented.  The default is :action_cable.
# Other possibilities are :pusher (see www.pusher.com) or
# :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # or :none, :pusher,  :simple_poller

# add this line if you need jQuery AND ARE NOT USING WEBPACK
# Hyperstack.import 'hyperstack/component/jquery', client_only: true

# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "\#{formatted_error_message}\\n\\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?
        RUBY
      end
      # whenever we modify the initializer its best to empty the cache, BUT
      # we only need to it once per generator execution
      run 'rm -rf tmp/cache' unless @cache_emptied_already
      @cache_emptied_already = true
    end
  end
end
