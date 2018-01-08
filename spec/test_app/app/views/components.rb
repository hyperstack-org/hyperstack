require 'opal'
require 'promise'
require 'hyper-react'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
end
require_tree './components'
