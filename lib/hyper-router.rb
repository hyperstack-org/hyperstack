# rubocop:disable Style/FileName

require 'hyper-component'

Hyperloop.import 'hyper-router/react-router-source'
Hyperloop.import 'hyper-router'

if RUBY_ENGINE == 'opal'
  no_router_source = `Opal.global.ReactRouter === undefined`
  no_router_dom_source = `Opal.global.ReactRouterDOM === undefined`
  if no_router_source || no_router_dom_source
    error = <<-ERROR
  No react-router.js or react-router-dom.js Available.

  A global 'ReactRouter' and 'ReactRouterDOM' must be defined before requiring 'hyper-router'.

  To USE THE BUILT-IN SOURCE:
    add 'require \"hyper-router/react-router-source\"'
    immediately before the 'require \"hyper-router\" directive.

  IF USING NPM/WEBPACK:
    add '\"react-router\": \"^4.1.1\"' and '\"react-router-dom\": \"^4.1.1\"' to your package.json.)
    ERROR
    raise error
  end

  require 'react/router'
  require 'react/router/dom'
  require 'react/router/history'

  require 'hyper-router/isomorphic_methods'
  require 'hyper-router/history'
  require 'hyper-router/location'
  require 'hyper-router/match'
  require 'hyper-router/class_methods'
  require 'hyper-router/component_methods'
  require 'hyper-router/instance_methods'

  require 'hyperloop/router/base'
  require 'hyperloop/router/browser'
  require 'hyperloop/router/mixin'
  require 'hyperloop/router/component'
  require 'hyperloop/router/hash'
  require 'hyperloop/router/memory'
  require 'hyperloop/router/static'
  require 'hyperloop/router'
else
  require 'opal'
  require 'hyper-router/isomorphic_methods'
  require 'hyper-router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
