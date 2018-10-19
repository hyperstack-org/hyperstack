require 'hyper-component'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
  #require 'react/ext/opal-jquery/element'
  require 'hyperstack/component/jquery'
end
require 'hyperstack/component/server'
require 'react/test/utils'
require 'reactrb/auto-import'
require 'js'
require 'hyper-store'

require_tree './components'
