require 'hyperstack/internal/component'

Hyperstack.import    'hyper-state'
Hyperstack.js_import 'react/react-source-browser', client_only: true, defines: %w[ReactDOM React]
Hyperstack.js_import 'react/react-source-server', server_only: true, defines: 'React'
Hyperstack.import    'browser/delay', client_only: true
Hyperstack.js_import 'react_ujs', defines: 'ReactRailsUJS'
Hyperstack.import    'hyper-component'  # TODO: confirm this does not break anything.  Added while converting hyperloop->hyperstack
Hyperstack.import    'hyperstack/component/auto-import'  # TODO: confirm we can cancel the import

if RUBY_ENGINE == 'opal'
  require 'hyperstack/internal/callbacks'
  require 'hyperstack/internal/auto_unmount'
  require 'native'
  require 'hyperstack/state/observer'
  require 'hyperstack/internal/component/validator'
  require 'hyperstack/component/element'
  require 'hyperstack/internal/component/react_wrapper'
  require 'hyperstack/component'
  require 'hyperstack/internal/component/should_component_update'
  require 'hyperstack/internal/component/tags'
  require 'hyperstack/component/event'
  require 'hyperstack/internal/component/rendering_context'
  require 'hyperstack/ext/component/object'
  require 'hyperstack/ext/component/number'
  require 'hyperstack/ext/component/boolean'
  require 'hyperstack/component/isomorphic_helpers'
  require 'hyperstack/component/react_api'
  require 'hyperstack/internal/component/top_level_rails_component'
  require 'hyperstack/component/while_loading'
  require 'hyperstack/internal/component/rescue_wrapper'
  require 'hyperstack/internal/component/while_loading_wrapper'

  require 'hyperstack/component/version'
else
  require 'opal'
  require 'opal-activesupport'
  require 'hyperstack/component/version'
  require 'hyperstack/internal/component/rails'
  require 'hyperstack/component/isomorphic_helpers'
  require 'hyperstack/ext/component/serializers'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  require 'react/react-source'
end
