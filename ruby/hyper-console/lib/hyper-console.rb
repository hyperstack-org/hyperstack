require "hyperloop/console/version"
require 'hyper-operation'
require 'hyperloop/console/hyper_console'
require 'hyperloop/console/evaluate'
Hyperloop.import 'hyper-console'

if RUBY_ENGINE == 'opal'
  require 'hyperloop/console/object_space'
  require 'securerandom'
else
  require 'hyperloop/console/engine'
  Opal.append_path File.expand_path('../', __FILE__).untaint
end
