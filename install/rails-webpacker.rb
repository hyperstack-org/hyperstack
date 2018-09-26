# Legacy Hyperloop

# ----------------------------------- Commit so we have good history of these changes

git :init
git add:    "."
git commit: "-m 'Initial commit: Rails base'"

# ----------------------------------- Add the gems

gem 'webpacker'
gem 'hyperloop', ">=0.9.1", "<1.0.0"
gem 'opal_hot_reloader', github: 'hyperstack-org/opal-hot-reloader'

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

# ----------------------------------- Create hyperstack.js

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

# ----------------------------------- Mount point

route "mount Hyperloop::Engine => '/hyperloop'"

# ----------------------------------- Hello World

route "root 'hyperloop#HelloWorld'"
file 'app/hyperloop/components/hello_world.rb', <<-CODE
class HelloWorld < Hyperloop::Component
  render do
    H1 { "Hello world from Legacy Hyperloop!" }
  end
end
CODE

# ----------------------------------- Commit Hyperloop setup

after_bundle do
  run 'bundle exec rails webpacker:install'
  git add:    "."
  git commit: "-m 'Hyperstack config complete'"
end
