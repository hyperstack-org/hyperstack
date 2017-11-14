if RUBY_ENGINE != 'opal'
  module React
    module Config
      extend self
      def environment=(value)
        config[:environment] = value
      end

      def config
        @config ||= default_config
      end

      def default_config
        {
          environment: ENV['RACK_ENV'] || 'development'
        }
      end
    end
  end
  module Hyperloop
    define_setting :prerendering, :off
  end
end
