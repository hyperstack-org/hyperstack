require 'hyperloop-config'
require 'hyper-component'
Hyperloop.import 'vis/source/vis.js', client_only: true
Hyperloop.import 'hyper-vis'
require 'opal-activesupport'
require 'hyperloop/vis/version'

if RUBY_ENGINE == 'opal'
  require 'vis'
  require 'hyper-component'
  require 'hyperloop/vis/graph2d/mixin'
  require 'hyperloop/vis/graph2d/component'
  require 'hyperloop/vis/graph3d/mixin'
  require 'hyperloop/vis/graph3d/component'
  require 'hyperloop/vis/network/mixin'
  require 'hyperloop/vis/network/component'
  require 'hyperloop/vis/timeline/mixin'
  require 'hyperloop/vis/timeline/component'
else
  require 'vis/railtie' if defined?(Rails)
  Opal.append_path __dir__.untaint
end