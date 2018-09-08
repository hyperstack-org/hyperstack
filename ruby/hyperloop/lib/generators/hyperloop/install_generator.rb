require_relative 'install_generator_base'
module Hyperloop
  class InstallGenerator < Rails::Generators::Base

    class_option 'skip-webpack', type: :boolean
    class_option 'skip-hot-reloader', type: :boolean
    class_option 'add-framework', type: :string

    def insure_yarn_loaded
      return if skip_webpack?
      begin
        yarn_version = `yarn --version`
        raise Errno::ENOENT if yarn_version.blank?
      rescue Errno::ENOENT
        raise Thor::Error.new("please insure the yarn command is available if using webpacker")
      end
    end

    def inject_react_file_js
      append_file 'app/assets/javascripts/application.js' do
        <<-'JS'
//= require hyperloop-loader
        JS
      end
    end

    def create_hyperloop_directories
      create_file 'app/hyperloop/components/.keep', ''
      create_file 'app/hyperloop/operations/.keep', ''
      create_file 'app/hyperloop/stores/.keep', ''
      create_file 'app/hyperloop/models/.keep', ''
    end

    def move_and_update_application_record
      unless File.exists? 'app/hyperloop/models/application_record.rb'
        `mv app/models/application_record.rb app/hyperloop/models/application_record.rb`
        create_file 'app/models/application_record.rb', <<-RUBY
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb see https://github.com/rails/rails/issues/29407

require 'models/application_record.rb'
        RUBY
      end
    end

    def create_policies_directory
      create_file 'app/policies/application_policy.rb', <<-RUBY
# app/policies/application_policy

# Policies regulate access to your public models
# The following policy will open up full access (but only in development)
# The policy system is very flexible and powerful.  See the documentation
# for complete details.
class Hyperloop::ApplicationPolicy
  # Allow any session to connect:
  always_allow_connection
  # Send all attributes from all public models
  regulate_all_broadcasts { |policy| policy.send_all }
  # Allow all changes to public models
  allow_change(to: :all, on: [:create, :update, :destroy]) { true }
  # allow remote access to all scopes - i.e. you can count or get a list of ids
  # for any scope or relationship
  ApplicationRecord.regulate_scope :all
end unless Rails.env.production?
        RUBY
    end

    def add_router
      generate "hyper:router", "App"
    end

    def add_webpacker_manifests
      return if skip_webpack?
      create_file 'app/javascript/packs/client_and_server.js', <<-JAVASCRIPT
//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                      // react-js library
History = require('history');                  // react-router history library
ReactRouter = require('react-router');         // react-router js library
ReactRouterDOM = require('react-router-dom');  // react-router DOM interface
ReactRailsUJS = require('react_ujs');          // interface to react-rails
// to add additional NPM packages call run yarn package-name@version
// then add the require here.
      JAVASCRIPT
      create_file 'app/javascript/packs/client_only.js', <<-JAVASCRIPT
//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
ReactDOM = require('react-dom');               // react-js client side code
jQuery = require('jquery');
// to add additional NPM packages call run yarn package-name@version
// then add the require here.
      JAVASCRIPT
      append_file 'config/initializers/assets.rb' do
        <<-RUBY
Rails.application.config.assets.paths << Rails.root.join('public', 'packs').to_s
        RUBY
      end
    end

    def add_webpacks
      return if skip_webpack?
      yarn 'react', '16'
      yarn 'react-dom', '16'
      yarn 'react-router', '4.2'
      yarn 'react-router-dom', '4.2'
      yarn 'history', '4.2'
      yarn 'react_ujs'
      yarn 'jquery'
    end

    def add_framework
      framework = options['add-framework']
      return unless framework
      generate "hyperloop:install_#{framework}", "--no-build"
    end

    def build_webpack
      system('bin/webpack')
    end

    # all generators should be run before the initializer due to the opal-rails opal-jquery
    # conflict

    def create_initializer
      create_file 'config/initializers/hyperloop.rb', <<-RUBY
# config/initializers/hyperloop.rb
# If you are not using ActionCable, see http://ruby-hyperloop.io/docs/models/configuring-transport/
Hyperloop.configuration do |config|
  config.transport = :action_cable # or :pusher or :simpler_poller or :none
  config.prerendering = :off # or :on
  config.import 'reactrb/auto-import' # will automatically bridge js components to hyperloop components
#{"  config.import 'jquery', client_only: true  # remove this line if you don't need jquery" if skip_webpack?}
  config.import 'opal-jquery', client_only: true # remove this line if you don't need jquery'
#{"  config.import 'opal_hot_reloader' if Rails.env.development?" unless options['skip-hot-reloader']}
end
        RUBY
    end

    def inject_engine_to_routes
      # this needs to be the first route, thus it must be the last method executed
      route 'mount Hyperloop::Engine => \'/hyperloop\''  # this route should be first in the routes file so it always matches
    end

    def add_opal_hot_reloader
      return if options['skip-hot-reloader']
      create_file 'Procfile', <<-TEXT
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec opal-hot-reloader -d app/hyperloop
      TEXT
      append_file 'app/assets/javascripts/application.js' do
        <<-RUBY
Opal.OpalHotReloader.$listen() // optional (port, false, poll_seconds) i.e. (8081, false, 1)
        RUBY
      end
      gem_group :development do
        gem 'opal_hot_reloader'
        gem 'foreman'
      end
    end

    def add_gems
      gem 'hyper-model', Hyperloop::VERSION
      gem 'hyper-router', Hyperloop::ROUTERVERSION
      #gem 'opal-rails', '~> 0.9.4'
      #gem 'opal-jquery'
      gem "opal-jquery", git: "https://github.com/opal/opal-jquery.git", branch: "master"
    end

    def install
      Bundler.with_clean_env do
        run "bundle install"
      end
    end

    private

    def skip_webpack?
      options['skip-webpack'] || !defined?(Webpacker)
    end
  end
end
