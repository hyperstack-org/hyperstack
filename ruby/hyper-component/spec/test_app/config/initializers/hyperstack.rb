%w[
  hyper-state
  hyperstack/autoloader
  hyperstack/autoloader_starter
  config/initializers/inflections.rb
].each { |r| Hyperstack.cancel_import r }

Hyperstack.import 'jquery', js_import: true, at_head: true, client_only: true
Hyperstack.import 'react-server', js_import: true, at_head: true, client_only: true
Hyperstack.import 'hyperstack/component/jquery', client_only: true
Hyperstack.import 'hyperstack/component/server'
