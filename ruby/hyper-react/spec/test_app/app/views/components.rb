require 'hyper-react'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
end
require 'react/server'
require 'react/test/utils'
require 'reactrb/auto-import'
require 'js'

require_tree './components'
