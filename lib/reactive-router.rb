if RUBY_ENGINE == 'opal'
  #require 'reactive-ruby' # how to require this conditionally????
  require 'promise'
  require 'react/router/react-router'
  require 'react/router'
  require 'react/router/dsl'
  require 'react/router/dsl/route'
  require 'react/router/dsl/index'
  require 'react/router/dsl/transition_context'
  require 'react/router/dsl/test'

else
  require 'opal'
  require 'reactive-ruby'
  #require 'reactive-router/window_location'
  require 'reactive-router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
