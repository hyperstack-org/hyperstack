require 'hyperloop/component/version'
require 'hyperloop-config'
Hyperloop.import 'hyper-component'
if RUBY_ENGINE == 'opal'
  module Hyperloop
    class Component
      # defining this before requring hyper-react will turn
      # off the hyper-react deprecation notice
    end
  end
  require 'hyper-react'
else
  require 'opal'
  require 'hyper-react'
  require 'react-rails'
  require 'opal-rails'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
