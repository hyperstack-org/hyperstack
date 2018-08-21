if RUBY_ENGINE == 'opal'
  module Hyperstack
    class << self
      attr_reader :options

      def init
        init_options
        execute_init_classes
      end

      def init_options
        return @options if @options
        @options = Hash.new(`Opal.HyperstackOptions`)
        @options.keys.each do |option|
          define_singleton_method(option) do
            @options[option]
          end
        end
      end

      def execute_init_classes
        if options.has_key?(:client_init_class_names)
          client_init_class_names.each do |constant|
            constant.constantize.send(:init)
          end
        end
      end
    end
  end
else
  module Hyperstack
    class << self
      attr_accessor :client_init_class_names
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

      def add_client_init_class_name(class_name)
        client_init_class_names << class_name
      end

      def configuration(&block)
        block.call(self)
      end

      def options_for_client
        @options_for_client
      end

      def options_hash_for_client
        opts = {}
        Hyperstack.options_for_client.each do |option|
          opts[option] = Hyperstack.send(option)
        end
        opts
      end
    end

    self.client_init_class_names = []
    self.prerendering = :off

    self.add_client_option(:client_init_class_names)
  end
end
