require 'opal'
require 'hyper-component'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
  require 'browser/interval'
  #require 'hyperstack/pusher'
end
require 'hyper-model'
require '_react_public_models'
require_tree './components'


# require 'opal'
# require 'promise'
# require 'hyper-react'
# if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
#   require 'browser'
#   require 'browser/delay'
# end
# require_tree './components'
