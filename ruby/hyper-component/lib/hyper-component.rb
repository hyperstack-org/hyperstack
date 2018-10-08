require 'hyperloop-config'
Hyperloop.import 'hyper-store'
Hyperloop.js_import 'react/react-source-browser', client_only: true, defines: ['ReactDOM', 'React']
Hyperloop.js_import 'react/react-source-server', server_only: true, defines: 'React'
Hyperloop.import 'browser/delay', client_only: true
Hyperloop.js_import 'react_ujs', defines: 'ReactRailsUJS'

if RUBY_ENGINE == 'opal'
  module Hyperloop
    class Component
    end
  end
  require 'native'
  require 'react/observable'
  require 'react/validator'
  require 'react/element'
  require 'react/api'
  require 'react/component'
  require 'react/component/dsl_instance_methods'
  require 'react/component/should_component_update'
  require 'react/component/tags'
  require 'react/component/base'
  require 'react/event'
  require 'react/rendering_context'
  require 'react/state'
  require 'react/object'
  require 'react/to_key'
  #require 'react/ext/opal-jquery/element' # now have to manually require this
  require 'reactive-ruby/isomorphic_helpers'
  require 'react/top_level'
  require 'react/top_level_render'
  require 'rails-helpers/top_level_rails_component'
  require 'reactive-ruby/version'
  module Hyperloop
    class Component
      def self.inherited(child)
        child.include(Mixin)
      end
    end
  end
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
