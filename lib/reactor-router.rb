if RUBY_ENGINE == 'opal'
  require 'reactor-router/component'
  require 'reactor-router/router'
  require 'reactor-router/version'
else
  require 'opal'
  require 'opal-react'
  require 'reactor-router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../../vendor', __FILE__).untaint
end

module ReactorRouter
end
