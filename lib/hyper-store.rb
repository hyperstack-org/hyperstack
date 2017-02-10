require 'hyper-react'

require 'hyper-store/base'
require 'hyper-store/class_methods'
require 'hyper-store/hyper_store'
require 'hyper-store/instance_methods'
require 'hyper-store/mutator_wrapper'
require 'hyper-store/state_wrapper/argument_validator'
require 'hyper-store/state_wrapper'
require 'hyper-store/version'

if RUBY_ENGINE != 'opal'
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
