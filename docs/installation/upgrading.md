# Hyperloop to Hyperstack HS2

These instructions are subject to change as the project mnatures.

## Gemfile
Update the gem files and remove any old 
```ruby
gem 'opal', github: 'janbiedermann/opal', branch: 'es6_import_export'
gem 'opal-autoloader', github: 'janbiedermann/opal-autoloader', branch: 'master'
gem 'hyper-business', github: 'janbiedermann/hyper-business', branch: 'ulysses'
gem 'hyper-gate', github: 'janbiedermann/hyper-gate', branch: 'ulysses'
#gem 'hyper-international', github: 'janbiedermann/hyper-international', branch: 'ulysses'
gem 'hyper-react', github: 'janbiedermann/hyper-react', branch: 'ulysses'
gem 'hyper-resource', github: 'janbiedermann/hyper-resource', branch: 'ulysses'
gem 'hyper-router', github: 'janbiedermann/hyper-router', branch: 'ulysses'
#gem 'hyper-spectre', github: 'janbiedermann/hyper-spectre', branch: 'master'
gem 'hyper-store', github: 'janbiedermann/hyper-store', branch: 'ulysses'
gem 'hyper-transport-actioncable', github: 'janbiedermann/hyper-transport-actioncable', branch: 'ulysses'
gem 'hyper-transport-store-redis', github: 'janbiedermann/hyper-transport-store-redis', branch: 'ulysses'
gem 'hyper-transport', github: 'janbiedermann/hyper-transport', branch: 'ulysses'
gem 'opal-webpack-compile-server', github: 'janbiedermann/opal-webpack-compile-server', branch: 'master'
```

Gems not needed (if not used) can be removed
```ruby
gem 'opal-jquery', git: 'https://github.com/opal/opal-jquery.git', branch: 'master'
gem 'libv8'
```

## app/hyperstack/hyperstack_webpack_loader.rb
Should be done by a installer task
```ruby
require 'opal'
require 'browser' # CLIENT ONLY
require 'browser/delay' # CLIENT ONLY
require 'opal-autoloader'
require 'hyper-store'
require 'hyper-react'
require 'hyper-router'
require 'hyper-transport-actioncable'
require 'hyper-transport'
require 'hyper-resource'
require 'hyper-business'
require 'react/auto-import'

require_tree 'stores'
require_tree 'models'
require_tree 'operations'
require_tree 'components'
```

## app/javascript/app.js
Should be done by a installer task
* __Suggestion__ to make a _hyperstack.js_ file soit is very clear that it is hyperstack related
```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import * as History from 'history';
import * as ReactRouter from 'react-router';
import * as ReactRouterDOM from 'react-router-dom';
import * as ReactRailsUJS from 'react_ujs';
import ActionCable from 'actioncable';

global.React = React;
global.ReactDOM = ReactDOM;
global.History = History;
global.ReactRouter = ReactRouter;
global.ReactRouterDOM = ReactRouterDOM;
global.ReactRailsUJS = ReactRailsUJS;
global.ActionCable = ActionCable;

import init_app from 'hyperstack_webpack_loader.rb';

init_app();
Opal.load('hyperstack_webpack_loader');
if (module.hot) {
    module.hot.accept('./app.js', function () {
        console.log('Accepting the updated app module!');
    })
}
```

## remove app/assets/javascripts/application.js
```javascript
//= require hyperloop-loader
```

## Remove gems because they conflict
* react-rails

## Remove hyperloop initializer and mount points
* config/initializers/hyperloop.rb
* config/routes.rb
  * mount Hyperloop::Engine => '/hyperloop'

## Install new webpack config
Should be done by a installer task
* config/webpack/development.js: https://github.com/janbiedermann/opal-webpack-loader-example-app/blob/master/config/webpack/development.js

## Add Yarn packages
* `$ yarn add opal-webpack-loader`
* `$ yarn add opal-webpack-resolver-plugin`
* `$ yarn add webpack-serve`

## Rename hyperloop to hyperstack
* `$ git mv app/hyperloop app/hyperstack`

## Remove Hyperloop regulators
* Remove `regulate_scope :all` from the _application_record_ and _models_
* `regulate: :always_allow` from all _models_

## Add to the ApplicationHelper
If using rails and the rails gem this could be already included
* include Hyperstack::ViewHelpers

## Replace react_component by hyper_component
In order to render only a component you need to add a line to the application_layout and include the `Hyperstack::ViewHelpers`
* Rename in views: `react_component` => `hyper_component`
* Add to application_layout.rb
  * `<%= hyper_script_tag(current_user_id: current_user.id, session_id: session.id, form_authenticity_token: form_authenticity_token) %>`

## Load pack before normal application sprockets
See the suggested rename at topic: `app/javascript/app.js`
* `<%= owl_include_tag '/packs/app.js' %>`
* `<%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>`

## Add changes to the package.json
### In scripts section
```javascript
"scripts": {
  "test": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --config=config/webpack/test.js; bundle exec opal-webpack-compile-server kill",
  "watch": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --watch --config=config/webpack/development.js; bundle exec opal-webpack-compile-server kill",
  "start": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && bundle exec webpack-serve --config ./config/webpack/development.js; bundle exec opal-webpack-compile-server kill",
  "build": "bundle exec opal-webpack-compile-server kill; bundle exec opal-webpack-compile-server && webpack --config=config/webpack/production.js; bundle exec opal-webpack-compile-server kill"
}
```

### Ensure you have @rails/webpacker version 4 or higher
* `$ npm install @rails/webpacker@4.12.0`

## Expand the application_helper
__Suggestion__ this should be included in `Hyperstack::ViewHelpers`
```ruby
  def owl_include_tag(path)
    case Rails.env
    when 'production'
      public, packs, asset = path.split('/')
      path = OpalWebpackManifest.lookup_path_for(asset)
      javascript_include_tag(path)
    when 'development' then javascript_include_tag('http://localhost:3035' + path[0..-4] + '_development' + path[-3..-1])
    when 'test' then javascript_include_tag(path[0..-4] + '_test' + path[-3..-1])
    end
  end
```

## Expand the assets
Add to the config/initializers/assets.rb
```ruby
class OpalWebpackManifest
  def self.manifest
    @manifest ||= JSON.parse(File.read(File.join(Rails.root, 'public', 'packs', 'manifest.json')))
  end

  def self.lookup_path_for(asset)
    manifest[asset]
  end
end
```

## Hyperstack models don't support all helper classes
__Suggestion__ this should be taken cared of if a cleaner way of detecting `RUBY_ENGINE == 'opal'` and where possible
stub the unsupported methods
```ruby
# app/hyperstack/models/application_record.rb
#  Abstract parent
if RUBY_ENGINE == 'opal'
  class ApplicationRecord
    def self.inherited(base)
      base.include(HyperRecord)
    end
  end
else
  class ApplicationRecord < ActiveRecord::Base
    # when updating this part, also update the ApplicationRecord in app/models/application_record.rb
    # for rails eager loading in production, so production doesn't fail
    self.abstract_class = true
    extend HyperRecord::ServerClassMethods
    include GenericApp::WhereWithRequestParams
  end
end
```

To prevent code like this:
```ruby
class NewModel < ApplicationRecord
  if RUBY_ENGINE != 'opal'
    establish_connection "other_database_#{Rails.env}".to_sym
    self.abstract_class = true
  end
end
```

## Remove old policy direcotie
* `$ git rm -r app/policies`

## Rename all Hyperloop models to the new Hyperstack
* `$ find ./hyperloop/models -type f -exec sed -i -e 's/Hyperloop::Model/Hyperstack::Model/' {} \;`

## Add action able if you use `hyper-transport-actioncable`
* `$ yarn add actioncable`
* add to `app/javascript/app.js`:
  * ```javascript
    import ActionCable from 'actioncable';
    global.ActionCable = ActionCable;
    ```

## Install Model handlers if used
* `$ bundle exec hyper-resource-installer`
* `$ bundle exec hyper-business-installer`
* `$ bundle exec hyper-gate-installer`

## Install new controller
__Suggestion__ Should be included in the _rails_ gem or if it can be used for other frameworks as well

app/controllers/hyperloop_api_controller.rb
```ruby
class HyperstackApiController < ApplicationController
  include Hyperstack::Transport::RequestProcessor

  def create
    resource_request = params

    resource_request.delete('action')
    resource_request.delete('controller')
    resource_request.delete('endpoint')
    resource_request.delete('format')
    resource_request.delete('timestamp')
    resource_request.delete('hyperstack_api')

    result = process_request(session.id, current_user, resource_request)

    respond_to do |format|
      format.json { render json: result, status: (result.has_key?(:error) ? :unprocessable_entitiy : :ok) }
    end
  end
end
```

## Add to routes
__Suggestion__ This should also be included if the new controller `HyperstackApiController` is also embedded
```ruby
resources :hyperstack_api, only: [:create], defaults: {format: :json}
```

## If using Foreman update your Procfile

```
web:         bundle exec puma
webpack_dev: yarn run start
```

## Top start the development server

+ `yarn run start` (this needs to keep running)
+ `bundle exec puma`
