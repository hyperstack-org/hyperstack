require 'hyperloop-config'
require 'rails/generators'

# remove these once lap29 is released ...
Hyperloop.js_import 'react/react-source-browser', client_only: true, defines: ['ReactDOM', 'React']
Hyperloop.js_import 'react/react-source-server', server_only: true, defines: 'React'
Hyperloop.js_import 'hyper-router/react-router-source', defines: ['ReactRouter', 'ReactRouterDOM', 'History']
Hyperloop.js_import 'react_ujs', defines: 'ReactRailsUJS'
# remove above once lap29 is released ...

Hyperloop.import 'reactrb/auto-import'
Hyperloop.import 'hyper-router'

require 'generators/hyperloop/install_generator'
require 'generators/hyper/component_generator'
require 'generators/hyper/router_generator'
begin
  require 'opal-rails'
  require 'hyper-model'
  require 'hyper-router'
rescue LoadError
end
require 'react-rails'
require 'opal-browser'
require 'mini_racer'
require 'hyperloop/version'
