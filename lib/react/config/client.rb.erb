if RUBY_ENGINE == 'opal'
  module React
    module Config
      extend self
      def environment=(value)
        raise "Environment cannot be configured at runtime."
      end

      def config
        hash = %x{
          Opal.hash({
            environment: <%= '"' + React::Config.config[:environment] + '"' %>
          })
        }
        hash
      end
    end
  end
end
