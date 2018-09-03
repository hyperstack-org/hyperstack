module Hyperstack
  module Record
    module ServerClassMethods
      def hyperstack_orm_driver
        @orm_driver ||= Hyperstack::Model::Driver::ActiveRecord.new(self)
      end

      def hyperstack_orm_driver=(driver)
        @orm_driver = driver.new(self)
      end

      # DSL for defining collection_query
      # @param name [Symbol] name of the method
      # @param options [Hash] known key: default_result, used client side
      def collection_query(name, &block)
        collection_queries[name] = {}
        define_method(name) do
          instance_exec(&block)
        end
        define_method("promise_#{name}") do
          p = Promise.new(success: proc { send(name) })
          p.resolve
          p
        end
      end

      # DSL for defining rest_class_methods
      # @param name [Symbol] name of the method
      # @param options [Hash] known key: default_result, used client side
      def rest_class_method(name, options = { default_result: '...' }, &block)
        rest_class_methods[name] = options
        singleton_class.send(:define_method, name) do |*args|
          if args.size > 0
            block.call(*args)
          else
            block.call
          end
        end
        singleton_class.send(:define_method, "promise_#{name}") do |*args|
          p = Promise.new(success: proc { send(name, *args) })
          p.resolve
          p
        end
      end

      # DSL for defining remote_methods
      # @param name [Symbol] name of the method
      # @param options [Hash] known key: default_result, used client side
      def remote_method(name, options = { default_result: '...' }, &block)
        remote_methods[name] = options
        define_method(name) do |*args|
          if args.size > 0
            instance_exec(*args, &block)
          else
            instance_exec(&block)
          end
        end
        define_method("promise_#{name}") do |*args|
          p = Promise.new(success: proc { send(name, *args) })
          p.resolve
          p
        end
      end

      # introspect defined collection_query
      # @return [Hash]
      def collection_queries
        @collection_queries ||= {}
      end

      # introspect defined rest_class_methods
      # @return [Hash]
      def rest_class_methods
        @rest_class_methods ||= {}
      end

      # introspect defined remote_methods
      # @return [Hash]
      def remote_methods
        @remote_methods ||= {}
      end

      # introspect defined scopes
      # @return [Hash]
      def model_scopes
        @model_scopes ||= {}
      end

      # defines a scope, wrapper around ORM method
      # @param name [Symbol] name of the args
      # @param *args additional args, passed to ORMs scope DSL
      def scope(name, *options)
        model_scopes[name] = options
        singleton_class.send(:define_method, "promise_#{name}") do |*args|
          p = Promise.new(success: proc { send(name, *args) })
          p.resolve
          p
        end
        super(name, *options)
      end
    end
  end
end