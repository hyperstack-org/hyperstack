if RUBY_ENGINE == 'opal'
  no_source = `Opal.global.ReactRouter === undefined`
  if no_source
    error = <<-ERROR
No react-router.js Available.

A global `ReactRouter` must be defined before requiring 'hyper-router'.

To USE THE BUILT-IN SOURCE:
  add 'require \"hyper-router/react-router-source\"'
  immediately before the 'require \"hyper-router\" directive.

IF USING NPM/WEBPACK:
  add "react-router": "~2.4.0" to your package.json.)
    ERROR
    raise error
  end
  require 'hyper-react'
  require 'promise'
  require 'promise_extras'
  require 'react/router'
  require 'react/router/dsl'
  require 'react/router/dsl/route'
  require 'react/router/dsl/index'
  require 'react/router/dsl/transition_context'
  require 'patches/react'
else
  require 'opal'
  require 'hyper-react'
  require 'react/router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
