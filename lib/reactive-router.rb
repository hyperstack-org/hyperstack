if RUBY_ENGINE == 'opal'
  require 'reactive-ruby'
  require 'reactive-router/component'
  require 'reactive-router/history'
  require 'reactive-router/router'
  require 'reactive-router/version'
else
  require 'opal'
  require 'reactive-ruby'
  require 'reactive-router/window_location'
  require 'reactive-router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end
