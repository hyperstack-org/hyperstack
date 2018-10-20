require 'opal'
require 'hyper-component'
if Hyperstack::Component::IsomorphicHelpers.on_opal_client?
  require 'browser'
  require 'browser/delay'
end
require 'hyper-state'
