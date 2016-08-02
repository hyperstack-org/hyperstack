require 'opal'
require 'react'
require 'reactrb'
if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  require 'browser'
  require 'browser/interval'
  require 'browser/delay'
  require 'synchromesh/pusher'
  # add any additional requires that can ONLY run on client here
end
require 'reactive-record'
require 'synchromesh'
require_tree './components'
require '_react_public_models'
