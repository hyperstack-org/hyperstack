require 'opal'
require 'react/react-source-browser'
require 'hyper-component'
require 'hyper-operation'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser/delay'
  require 'browser/interval'
  require 'hyperloop/pusher'
end
require_tree './components'
