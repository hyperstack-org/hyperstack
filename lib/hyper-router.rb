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

  require 'hyperstack/router/base'
  require 'hyperstack/router/browser'
  require 'hyperstack/router/mixin'
  require 'hyperstack/router/component'
  require 'hyperstack/router/hash'
  require 'hyperstack/router/memory'
  require 'hyperstack/router/static'
  require 'hyperstack/router'
else
  require 'opal'
  require 'hyper-router/isomorphic_methods'
  require 'hyper-router/version'

  Opal.append_path File.expand_path('../', __FILE__).untaint
end
