require 'opal'
require 'hyper-component'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
  require 'browser/interval'
end
require 'hyper-state'
