require 'opal'
require 'react'
require 'hyper-mesh'

if React::IsomorphicHelpers.on_opal_client?
  #require 'browser' # breaks poltergeist
  require 'browser/support'
  require 'browser/event'
  require 'browser/window'
  require 'browser/delay'
  require 'browser/interval'
  require 'hyperloop/pusher'
end
require '_react_public_models'
require_tree './components'
