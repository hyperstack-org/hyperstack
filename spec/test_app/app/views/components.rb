require 'opal'
require 'react'
#require 'hyper-trace'
require 'hyper-mesh'

if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  #require 'browser' # breaks poltergeist
  require 'browser/interval'
  require 'browser/delay'
  require 'hyper-mesh/pusher'
end
require '_react_public_models'
require_tree './components'
