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
Hyperstack.import 'promise', client_only: true
Hyperstack.import 'browser', client_only: true
Hyperstack.import 'browser/delay', client_only: true

