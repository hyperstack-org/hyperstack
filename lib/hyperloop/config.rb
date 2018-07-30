if RUBY_ENGINE == 'opal'
  module Hyperloop
    class << self
      def init_options
        return @options if @options
        @options = Hash.new(`Opal.HyperloopOpts`)
        @options.keys.each do |option|
          define_singleton_method(option) do
            @options[option]
          end
        end
      end

      attr_reader :options
    end
  end
else
  module Hyperloop
    class << self
      attr_accessor :prerendering

      def add_client_option(option)
        @options_for_client ||= Set.new
        @options_for_client << option
      end

      def add_client_options(options)
        options.each do |option|
          add_client_option(option)
        end
      end

      def options_for_client
        @options_for_client
      end

      def options_hash_for_client
        opts = {}
        Hyperloop.options_for_client.each do |option|
          opts[option] = Hyperloop.send(option)
        end
        opts
      end
    end

    self.prerendering = :off
  end
end
