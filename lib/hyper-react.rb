require 'hyperloop-config'
Hyperloop.import 'hyper-store'
Hyperloop.import 'react/react-source-browser', client_only: true
Hyperloop.import 'react/react-source-server', server_only: true
Hyperloop.import 'browser/delay', client_only: true
Hyperloop.import 'hyper-react'
Hyperloop.import 'react_ujs'

if RUBY_ENGINE == 'opal'
  module Hyperloop
    class Component
    end
  end

  if `Opal.global.React === undefined || Opal.global.React.version === undefined`
    raise [
      "No React.js Available",
      "",
      "A global `React` must be defined before requiring 'hyper-react'",
      "",
      "To USE THE BUILT-IN SOURCE: ",
      "   add 'require \"react/react-source-browser\"' immediately before the 'require \"hyper-react\" directive.",
      "IF USING WEBPACK:",
      "   add 'react' to your webpack manifest."
    ].join("\n")
  end
  require 'react/top_level'
  require 'react/top_level_render'
  require 'react/observable'
  require 'react/validator'
  require 'react/component'
  require 'react/component/dsl_instance_methods'
  require 'react/component/should_component_update'
  require 'react/component/tags'
  require 'react/component/base'
  require 'react/element'
  require 'react/event'
  require 'react/api'
  require 'react/rendering_context'
  require 'react/state'
  require 'react/object'
  require 'react/to_key'
  require 'react/ext/opal-jquery/element'
  require 'reactive-ruby/isomorphic_helpers'
  require 'rails-helpers/top_level_rails_component'
  require 'reactive-ruby/version'
  module Hyperloop
    class Component
      def self.inherited(child)
        child.include(Mixin)
      end
    end
  end
  React::Component.deprecation_warning(
    'component.rb',
    "Requiring 'hyper-react' is deprecated.  Use gem 'hyper-component', and require 'hyper-component' instead."
  ) unless defined? Hyperloop::Component::VERSION
else
  require 'opal'

  require 'hyper-store'
  require 'opal-activesupport'
  require 'reactive-ruby/version'
  require 'reactive-ruby/rails' if defined?(Rails)
  require 'reactive-ruby/isomorphic_helpers'
  require 'reactive-ruby/serializers'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  require 'react/react-source'
end
