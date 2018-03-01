if RUBY_ENGINE != 'opal'
  module Hyperloop
    define_setting :prerendering, :off
  end
end
