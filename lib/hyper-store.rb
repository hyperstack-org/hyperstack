require 'set'
require 'hyper-store/base_store_class'
require 'hyper-store/class_methods'
require 'hyper-store/dispatch_receiver'
require 'hyper-store/instance_methods'
require 'hyper-store/mutator_wrapper'
require 'hyper-store/state_wrapper/argument_validator'
require 'hyper-store/state_wrapper'
require 'hyper-store/version'
require 'hyperloop/store'
require 'hyperloop/application/boot'
require 'hyperloop/store/mixin'
require 'react/state'

if RUBY_ENGINE != 'opal'
  require 'opal'
  Opal.append_path(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperloop'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'stores')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperloop')))
  elsif Dir.exist?(File.join('hyperloop'))
    # Opal.append_path(File.expand_path(File.join('hyperloop', 'stores')))
    Opal.append_path(File.expand_path(File.join('hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('hyperloop')))
  end
end
