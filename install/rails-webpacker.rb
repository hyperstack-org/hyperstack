# Hyperstack

# ----------------------------------- Commit so we have good history of these changes

git :init
git add:    "."
git commit: "-m 'Initial commit: Rails base'"

# ----------------------------------- Add the gems

gem 'webpacker'
gem 'rails-hyperstack', github: 'hyperstack-org/hyperstack', branch: 'edge', glob: 'ruby/*/*.gemspec'

gem_group :development do
  gem 'foreman'
end

# ----------------------------------- Create the folders

run 'mkdir app/hyperstack'
run 'mkdir app/hyperstack/components'
run 'mkdir app/hyperstack/stores'
run 'mkdir app/hyperstack/models'
run 'mkdir app/hyperstack/operations'

# ----------------------------------- Add .keep files

run 'touch app/hyperstack/stores/.keep'
run 'touch app/hyperstack/models/.keep'
run 'touch app/hyperstack/operations/.keep'

# ----------------------------------- Create the HyperCompnent base class

file 'app/hyperstack/components/hyper_component.rb', <<-CODE
class HyperComponent
  include Hyperstack::Component
  include Hyperstack::State::Observer
end
CODE

# ----------------------------------- Create the Hyperstack config

file 'config/initializers/hyperstack.rb', <<-CODE
# config/initializers/hyperstack.rb
# If you are not using ActionCable, see http://hyperstack.orgs/docs/models/configuring-transport/
Hyperstack.configuration do |config|
  # config.transport = :action_cable
  config.prerendering = :off # or :on
  config.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
  config.import 'hyperstack/component/jquery', client_only: true # remove this line if you don't need jquery
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
end
CODE

# ----------------------------------- Add NPM modules

run 'yarn add react'
run 'yarn add react-dom'
run 'yarn add react-router'

# ----------------------------------- Create hyperstack.js

file 'app/javascript/packs/hyperstack.js', <<-CODE
// Import all the modules
import React from 'react';
import ReactDOM from 'react-dom';

// for opal/hyperstack modules to find React and others they must explicitly be saved
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

# ----------------------------------- application.js

inject_into_file 'app/assets/javascripts/application.js', before: %r{//= require_tree .} do
<<-CODE
//= require jquery
//= require jquery_ujs
//= require hyperstack-loader
CODE
end

# ----------------------------------- Procfile

file 'Procfile', <<-CODE
web: bundle exec puma
hot: hyperstack-hotloader -p 25222 -d app/hyperstack/
CODE

# ----------------------------------- Mount point

route "mount Hyperstack::Engine => '/hyperstack'"

# ----------------------------------- Hello World

route "root 'hyperstack#HelloWorld'"
file 'app/hyperstack/components/hello_world.rb', <<-CODE
class HelloWorld < HyperComponent
  render do
    H1 { "Hello world from Hyperstack edge!" }
  end
end
CODE

# ----------------------------------- Commit Hyperstack setup

after_bundle do
  run 'bundle exec rails webpacker:install'
  git add:    "."
  git commit: "-m 'Hyperstack config complete'"
end
