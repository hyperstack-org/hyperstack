# rubocop:disable Style/FileName

require 'hyper-react'

if RUBY_ENGINE == 'opal'
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
