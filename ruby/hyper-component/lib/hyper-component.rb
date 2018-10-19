require 'hyperstack/internal/component'

Hyperstack.import    'hyper-state'
Hyperstack.js_import 'react/react-source-browser', client_only: true, defines: %w[ReactDOM React]
Hyperstack.js_import 'react/react-source-server', server_only: true, defines: 'React'
Hyperstack.import    'browser/delay', client_only: true
Hyperstack.js_import 'react_ujs', defines: 'ReactRailsUJS'
Hyperstack.import    'hyper-component'  # TODO: confirm this does not break anything.  Added while converting hyperloop->hyperstack

if RUBY_ENGINE == 'opal'
  require 'native'
  require 'hyperstack/state/observer'
  require 'hyperstack/internal/component/validator'
  require 'react/element'
  require 'hyperstack/internal/component/react_wrapper'
  require 'hyperstack/component'
  require 'hyperstack/internal/component/should_component_update'
  require 'hyperstack/internal/component/tags'
  require 'hyperstack/component/event'
  require 'react/rendering_context'
  require 'hyperstack/ext/component/object'
  require 'hyperstack/ext/component/number'
  require 'hyperstack/ext/component/boolean'
  require 'reactive-ruby/isomorphic_helpers'
  require 'hyperstack/component/react_api'
  require 'hyperstack/internal/component/top_level_rails_component'
  require 'reactive-ruby/version'
else
  require 'opal'

  require 'opal-activesupport'
  require 'reactive-ruby/version'
  require 'reactive-ruby/rails' if defined?(Rails)
  require 'reactive-ruby/isomorphic_helpers'
  require 'reactive-ruby/serializers'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  require 'react/react-source'
end
