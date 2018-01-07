require 'opal'
require 'promise'
require 'hyper-react'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser/support'
  require 'browser/event'
  require 'browser/window'
  require 'browser/delay'
end
require_tree './components'
