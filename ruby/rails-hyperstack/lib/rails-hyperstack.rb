require 'hyperstack-config'
require 'rails/generators'
require 'hyper-state'

# remove these once lap29 is released ...
Hyperstack.js_import 'react/react-source-browser', client_only: true, defines: ['ReactDOM', 'React']
Hyperstack.js_import 'react/react-source-server', server_only: true, defines: 'React'
#Hyperstack.js_import 'hyper-router/react-router-source', defines: ['ReactRouter', 'ReactRouterDOM', 'History']
Hyperstack.js_import 'react_ujs', defines: 'ReactRailsUJS'
# remove above once lap29 is released ...

Hyperstack.import 'hyper-router'
Hyperstack.import 'hyper-model'
Hyperstack.import 'hyper-state'

require 'generators/hyperstack/install_generator'
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
require 'hyperstack/version'

class RailsHyperstack < Rails::Railtie
  rake_tasks do
    Dir[File.join(File.dirname(__FILE__),'tasks/hyperstack/*.rake')].each { |f| puts "loading #{f}"; load f }
  end
end
