# rubocop:disable Style/FileName

require 'hyper-component'

Hyperstack.js_import 'hyperstack/router/react-router-source', defines: ['ReactRouter', 'ReactRouterDOM', 'History']
Hyperstack.import 'hyper-router'

if RUBY_ENGINE == 'opal'
  require 'react/router'
  require 'react/router/dom'
  require 'react/router/history'

  require 'hyperstack/internal/router/isomorphic_methods'
  require 'hyperstack/router/history'
  require 'hyperstack/router/location'
  require 'hyperstack/router/match'
  require 'hyperstack/internal/router/class_methods'
  require 'hyperstack/internal/router/helpers'
  require 'hyperstack/internal/router/instance_methods'

  require 'hyperstack/router/helpers'
  require 'hyperstack/router'
else
  require 'opal'
  require 'hyperstack/internal/router/isomorphic_methods'
  require 'hyperstack/router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
