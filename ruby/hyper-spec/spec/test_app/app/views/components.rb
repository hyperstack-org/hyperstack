require 'opal'
require 'promise'
require 'hyper-component'
require 'hyper-state'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
end
require_tree './components'
