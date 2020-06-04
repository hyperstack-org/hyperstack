# Hyperstack

# ----------------------------------- Commit so we have good history of these changes

git :init
git add:    "."
git commit: "-m 'Initial commit: Rails base'"

# ----------------------------------- Add the gems

gem 'webpacker'
gem 'rails-hyperstack', '~> 1.0.alpha1.0'
gem_group :development do
  gem 'foreman'
end

# ----------------------------------- Ensure Sqlite has a valid version

# gsub_file 'Gemfile', /gem\s+'sqlite3'(?!,\s+'.*')\n/, "gem 'sqlite3', '~> 1.3.6'\n"
# gsub_file 'Gemfile', /gem\s+'sqlite3'(?!,\s+'.*')\n/, "gem 'pg'"

# ----------------------------------- Create the folders

run 'mkdir app/hyperstack'
run 'mkdir app/hyperstack/components'
run 'mkdir app/hyperstack/stores'
run 'mkdir app/hyperstack/models'
run 'mkdir app/hyperstack/operations'
run 'mkdir app/policies'

# ----------------------------------- Add .keep files

run 'touch app/hyperstack/stores/.keep'
run 'touch app/hyperstack/models/.keep'
run 'touch app/hyperstack/operations/.keep'

# ----------------------------------- Create the HyperCompnent base class

file 'app/hyperstack/components/hyper_component.rb', <<-CODE
class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observable
  param_accessor_style :accessors
end
CODE

# ----------------------------------- Create the public ApplicationRecord base class

file 'app/hyperstack/models/application_record.rb', <<-CODE
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  regulate_scope all: true
end
CODE

# ----------------------------------- reference the public application_record.rb file

file 'app/models/application_record.rb', <<-CODE, force: true
# app/models/application_record.rb
# the presence of this file prevents rails migrations from recreating application_record.rb
# see https://github.com/rails/rails/issues/29407

# BH - I am not sure this is right
# require 'models/application_record.rb'
CODE

# ----------------------------------- Create the Hyperstack config

file 'config/initializers/hyperstack.rb', <<-CODE
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

# ----------------------------------- Create thyperstack.js

file 'app/javascript/packs/hyperstack.js', <<-CODE
// Import all the modules
import React from 'react';
import ReactDOM from 'react-dom';
 // for opal/hyperloop modules to find React and others they must explicitly be saved
// to the global space, otherwise webpack will encapsulate them locally here
global.React = React;
global.ReactDOM = ReactDOM;
CODE

# ----------------------------------- View template

inject_into_file 'app/views/layouts/application.html.erb', before: %r{<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>} do
  <<-CODE
  <%= javascript_pack_tag 'hyperstack' %>
  CODE
  end

# ----------------------------------- Add a default policy

file 'app/policies/application_policy.rb', <<-CODE
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
# don't forget to provide a policy before production...
::Rails.logger.debug("WARNING: You need to define a Hyperstack policy for production") if Rails.env.production?
CODE

# ----------------------------------- Add NPM modules

run 'yarn add react@16'
run 'yarn add react-dom@16'
run 'yarn add react-router@^5.0.0'
run 'yarn add react-router-dom@^5.0.0'
# run 'yarn add history' # this will be brought in by react-router
run 'yarn add react_ujs@^2.5.0'
run 'yarn add jquery@^3.4.1'

  # ----------------------------------- application.js

inject_into_file 'app/assets/javascripts/application.js', before: %r{//= require_tree .} do
<<-CODE
//= require jquery
//= require jquery_ujs
//= require hyperstack-loader
CODE
end

# ----------------------------------- Uglifier for ES6

gsub_file 'config/environments/production.rb', /(?:\:uglifier)\n/, "Uglifier.new(harmony: true)\n"

# ----------------------------------- Procfile

file 'Procfile', <<-CODE
web: bundle exec rails s -b 0.0.0.0
hot: hyperstack-hotloader -p 25222 -d app/hyperstack/
CODE

# ----------------------------------- App

# must be inserted BEFORE the engine mount so it ends up after in the route file!
route "get '/(*other)', to: 'hyperstack#app'"

file 'app/hyperstack/components/app.rb', <<-CODE
# app/hyperstack/component/app.rb

# This is your top level component, the rails router will
# direct all requests to mount this component.  You may
# then use the Route psuedo component to mount specific
# subcomponents depending on the URL.

class App < HyperComponent
  include Hyperstack::Router

  # define routes using the Route psuedo component.  Examples:
  # Route('/foo', mounts: Foo)                : match the path beginning with /foo and mount component Foo here
  # Route('/foo') { Foo(...) }                : display the contents of the block
  # Route('/', exact: true, mounts: Home)     : match the exact path / and mount the Home component
  # Route('/user/:id/name', mounts: UserName) : path segments beginning with a colon will be captured in the match param
  # see the hyper-router gem documentation for more details

  render(DIV) do
    H1 { "Hello world from Hyperstack!" }
    BUTTON {"Click me"}.on(:click) do
      alert("All working!")
    end
  end
end
CODE

# ----------------------------------- Engine mount point

# must be inserted AFTER route get ... so it ends up before in the route file!
route "mount Hyperstack::Engine => '/hyperstack'"


# ----------------------------------- Commit Hyperstack setup and create db

after_bundle do
  run 'bundle exec rails webpacker:install'
  git add:    "."
  git commit: "-m 'Hyperstack config complete'"
  run 'rake db:create'
end
