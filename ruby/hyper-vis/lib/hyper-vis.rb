require 'opal-activesupport'

if RUBY_ENGINE == 'opal'
  require 'vis'
  require 'hyper-component'
  require 'hyperstack/vis/graph2d/mixin'
  require 'hyperstack/vis/graph2d/component'
  require 'hyperstack/vis/graph3d/mixin'
  require 'hyperstack/vis/graph3d/component'
  require 'hyperstack/vis/network/mixin'
  require 'hyperstack/vis/network/component'
  require 'hyperstack/vis/timeline/mixin'
  require 'hyperstack/vis/timeline/component'
else
  require 'vis/railtie' if defined?(Rails)
  Opal.append_path __dir__.untaint
end