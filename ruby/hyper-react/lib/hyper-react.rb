require 'hyperloop-config'
require 'hyper-component'
require 'react/version'
Hyperloop.import 'hyper-react'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
