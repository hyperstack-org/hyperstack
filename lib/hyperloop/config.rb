if RUBY_ENGINE != 'opal'
  module Hyperloop
    def prerendering
      :off
    end
  end
end
