require 'opal'
require 'hyper-component'
if React::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
end
require 'hyper-store'

require_tree './components'
