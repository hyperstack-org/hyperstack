require 'opal'
require 'hyper-component'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
  require 'browser/interval'
  #require 'hyperloop/pusher'
end
require 'hyper-model'
require '_react_public_models'
require_tree './components'


# require 'opal'
# require 'promise'
# require 'hyper-react'
# if React::IsomorphicHelpers.on_opal_client?
#   require 'browser'
#   require 'browser/delay'
# end
# require_tree './components'
