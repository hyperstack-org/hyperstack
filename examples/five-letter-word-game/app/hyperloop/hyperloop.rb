# app/views/components.rb
require 'opal'
require 'react/react-source'
require 'hyper-react'
require 'hyper-operation'
require 'hyper-store'

if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  require 'browser'
  require 'browser/interval'
  require 'browser/delay'
  #require 'hyperloop/pusher'
  # add any additional requires that can ONLY run on client here
end
require_tree './components'
require_tree './lib'
require_tree './models'
require_tree './operations'
require_tree './stores'
