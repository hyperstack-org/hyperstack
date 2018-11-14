require 'hyperstack-config'

module Hyperstack

  define_setting :prerendering, :off if RUBY_ENGINE != 'opal'

end
