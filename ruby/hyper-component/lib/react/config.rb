if RUBY_ENGINE != 'opal'
  module Hyperstack
    define_setting :prerendering, :off
  end
end
