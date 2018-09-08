# Hyperstack 1.0 ALPHA Rails Template

# ----------------------------------- Commit so we have good history of these changes

git :init
git add:    "."
git commit: "-m 'Initial commit: Rails base'"

# ----------------------------------- Add the gems

gem 'webpacker'
gem 'opal-sprockets', '~> 0.4.2.0.11.0.3.1' # to ensure we have the latest
gem "opal-jquery", git: "https://github.com/opal/opal-jquery.git", branch: "master"
gem 'hyperloop', git: 'https://github.com/ruby-hyperloop/hyperloop', branch: 'edge'
gem 'hyper-react', git: 'https://github.com/ruby-hyperloop/hyper-react', branch: 'edge'
gem 'hyper-component', git: 'https://github.com/ruby-hyperloop/hyper-component', branch: 'edge'
gem 'hyper-router', git: 'https://github.com/ruby-hyperloop/hyper-router', branch: 'edge'
gem 'hyper-store', git: 'https://github.com/ruby-hyperloop/hyper-store', branch: 'edge'
gem 'hyperloop-config', git: 'https://github.com/ruby-hyperloop/hyperloop-config', branch: 'edge'
gem 'opal_hot_reloader', git: 'https://github.com/fkchang/opal-hot-reloader.git'

gem_group :development do
  gem 'foreman'
end

# ----------------------------------- Create the folders

run 'mkdir app/hyperloop'
run 'mkdir app/hyperloop/components'
run 'mkdir app/hyperloop/stores'
run 'mkdir app/hyperloop/models'
run 'mkdir app/hyperloop/operations'

# ----------------------------------- Add .keep files

run 'touch app/hyperloop/components/.keep'
run 'touch app/hyperloop/stores/.keep'
run 'touch app/hyperloop/models/.keep'
run 'touch app/hyperloop/operations/.keep'

# ----------------------------------- Create the Hyperloop config

file 'config/initializers/hyperloop.rb', <<-CODE
Hyperloop.configuration do |config|
  # config.transport = :action_cable
  config.import 'reactrb/auto-import'
  config.import 'opal_hot_reloader'
  config.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
end
CODE

# ----------------------------------- Add NPM modules

run 'yarn add react'
run 'yarn add react-dom'
run 'yarn add react-router'

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

# ----------------------------------- application.js

inject_into_file 'app/assets/javascripts/application.js', before: %r{//= require_tree .} do
<<-CODE
//= require jquery
//= require jquery_ujs
//= require hyperloop-loader
CODE
end

# ----------------------------------- Procfile

file 'Procfile', <<-CODE
web: bundle exec puma
hot: opal-hot-reloader -p 25222 -d app/hyperloop/
CODE

# ----------------------------------- OpalHotReloader client

file 'app/hyperloop/components/hot_loader.rb', <<-CODE
require 'opal_hot_reloader'
OpalHotReloader.listen(25222, false)
CODE

# ----------------------------------- Hello World

route "root 'hyperloop#HelloWorld'"

file 'app/hyperloop/components/hello_world.rb', <<-CODE
class HelloWorld < Hyperloop::Component
  render do
    H1 { "Hello world from Hyperstack!" }
  end
end
CODE

# ----------------------------------- Commit Hyperloop setup

after_bundle do
  run 'bundle exec rails webpacker:install'
  git add:    "."
  git commit: "-m 'Hyperstack config complete'"
end
