require 'opal'
require 'browser' # CLIENT ONLY
require 'browser/delay' # CLIENT ONLY
require 'opal-autoloader'

require 'hyper-store'
require 'hyper-react'
require 'hyper-router'
require 'hyper-transport-actioncable'
require 'hyper-transport'
require 'hyper-resource'
require 'hyper-business'
require 'react/auto-import'

require_tree 'stores'
# require_tree 'models'
require_tree 'operations'
require_tree 'components'

# Hyperstack::TopLevel.on_ready_mount(Home)
