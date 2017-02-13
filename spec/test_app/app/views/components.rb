require 'opal'
require 'react/react-source'
require 'hyper-react'
require 'hyper-operation'
if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  require 'browser/delay'
end
require_tree './components'
