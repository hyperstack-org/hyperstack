require 'set'
require 'hyper-store/base_store_class'
require 'hyper-store/class_methods'
require 'hyper-store/dispatch_receiver'
require 'hyper-store/instance_methods'
require 'hyper-store/mutator_wrapper'
require 'hyper-store/state_wrapper/argument_validator'
require 'hyper-store/state_wrapper'
require 'hyper-store/version'
require 'hyperstack/store'
require 'hyperstack/application/boot'
require 'hyperstack/store/mixin'
require 'react/state'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperstack'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperstack', 'stores')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperstack')))
  elsif Dir.exist?(File.join('hyperstack'))
    # Opal.append_path(File.expand_path(File.join('hyperstack', 'stores')))
    Opal.append_path(File.expand_path(File.join('hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('hyperstack')))
  end
end
