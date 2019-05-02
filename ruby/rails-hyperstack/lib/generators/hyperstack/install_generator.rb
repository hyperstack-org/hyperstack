require_relative 'install_generator_base'
module Hyperstack
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

    APPJS = 'app/assets/javascripts/application.js'

    def inject_react_file_js
      code = ""
      unless File.foreach(APPJS).any?{ |l| l['//= require jquery'] }
        code +=
        <<-CODE
//= require jquery
//= require jquery_ujs
        CODE
      end
      unless File.foreach(APPJS).any?{ |l| l['//= require hyperstack-loader'] }
        code +=
        <<-CODE
//= require hyperstack-loader
        CODE
      end
      return if code == ""
      inject_into_file 'app/assets/javascripts/application.js', before: %r{//= require_tree .} do
        code
      end
    end

    def create_hyperstack_files_and_directories
      create_file 'app/hyperstack/components/hyper_component.rb', <<-RUBY
  class HyperComponent
    include Hyperstack::Component
    include Hyperstack::State::Observer
    param_accessor_style :accessors
  end
        RUBY
      create_file 'app/hyperstack/operations/.keep', ''
      create_file 'app/hyperstack/stores/.keep', ''
      create_file 'app/hyperstack/models/.keep', ''
    end

    def move_and_update_application_record
      unless File.exists? 'app/hyperstack/models/application_record.rb'
        `mv app/models/application_record.rb app/hyperstack/models/application_record.rb`
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
class Hyperstack::ApplicationPolicy
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
      route "get '/(*other)', to: 'hyperstack#app'"
    end

    def add_webpackin
      run 'yarn add react'
      run 'yarn add react-dom'
      run 'yarn add react-router'
      create_file 'app/javascript/packs/hyperstack.js', <<-CODE
        // Import all the modules
        import React from 'react';
        import ReactDOM from 'react-dom';

        // for opal/hyperstack modules to find React and others they must explicitly be saved
        // to the global space, otherwise webpack will encapsulate them locally here
        global.React = React;
        global.ReactDOM = ReactDOM;
        CODE
      inject_into_file 'app/views/layouts/application.html.erb', before: %r{<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>} do
<<-CODE
<%= javascript_pack_tag 'hyperstack' %>
CODE
      end
      gem 'webpacker'
    end


if false
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
      generate "hyperstack:install_#{framework}", "--no-build"
    end

    def build_webpack
      system('bin/webpack')
    end
end
    # all generators should be run before the initializer due to the opal-rails opal-jquery
    # conflict

    def create_initializer
      create_file 'config/initializers/hyperstack.rb', <<-CODE
      # config/initializers/hyperstack.rb
      # If you are not using ActionCable, see http://hyperstack.orgs/docs/models/configuring-transport/
      Hyperstack.configuration do |config|
        config.transport = :action_cable
        config.prerendering = :off # or :on
        config.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
        config.import 'hyperstack/component/jquery', client_only: true # remove this line if you don't need jquery
        config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
      end

      # useful for debugging
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
      CODE
    end

    def inject_engine_to_routes
      # this needs to be the first route, thus it must be the last method executed
      route 'mount Hyperstack::Engine => \'/hyperstack\''  # this route should be first in the routes file so it always matches
    end

    def add_opal_hot_reloader
      return if options['skip-hot-reloader']
      create_file 'Procfile', <<-TEXT
web:        bundle exec rails s -b 0.0.0.0
hot-loader: bundle exec hyperstack-hotloader -p 25222 -d app/hyperstack
      TEXT
      gem_group :development do
        gem 'foreman'
      end
    end

    def add_gems
    end

    def install
      Bundler.with_clean_env do
        run "bundle install"
      end
      run 'bundle exec rails webpacker:install'
    end

    private

    def skip_webpack?
      options['skip-webpack'] || !defined?(Webpacker)
    end
  end
end
