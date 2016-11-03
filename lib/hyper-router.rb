if RUBY_ENGINE == 'opal'
  # require 'reactrb' # how to require this conditionally????
  require 'hyper-react'
  require 'promise'
  require 'promise_extras'
  require 'react/router/react-router'
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
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
