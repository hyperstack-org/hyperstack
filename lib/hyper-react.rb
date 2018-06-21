if RUBY_ENGINE == 'opal'
  require 'browser/delay'
  require 'hyper-store'
  require 'react/top_level'
  require 'react/top_level_render'
  require 'react/observable'
  require 'react/validator'

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
  require 'reactive-ruby/isomorphic_helpers'
  require 'hyperloop/component/mixin'
  require 'hyperloop/component'
  require 'hyperloop/component/version'
else
  require 'opal'
  require 'hyper-store'
  require 'opal-activesupport'
  require 'opal-browser'
  require 'reactive-ruby/isomorphic_helpers'
  require 'reactive-ruby/serializers'
  require 'hyperloop/component/version'
  Opal.append_path File.expand_path('../', __FILE__).untaint
  unless defined?(Rails)
    Opal.append_path File.expand_path('hyperloop').untaint
  end
end
