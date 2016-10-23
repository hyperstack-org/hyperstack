require 'opal'
require 'react'
require 'reactrb'
if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  #require 'browser' # breaks poltergeist
  require 'browser/interval'
  require 'browser/delay'
  require 'synchromesh/pusher'
  require 'hyper-trace'
end
require 'reactive-record'
require 'synchromesh'
require '_react_public_models'
require_tree './components'
