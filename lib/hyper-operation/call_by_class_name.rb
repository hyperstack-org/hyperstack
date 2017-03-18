module Hyperloop
  class Operation
  end
end

# patch so that we recognize Foo(...) as an operation inside a React Component
module React
  module Component
    module Tags

      private

      # redefine find_component so if its a HyperOperation we return nil which will
      # let Object.method_missing (see below) handle the method call to run.
      def find_component(name)
        component = lookup_const(name)
        return nil if component && component < Hyperloop::Operation
        if component && !component.method_defined?(:render)
          raise "#{name} does not appear to be a react component."
        end
        component
      end
    end
  end
end

class Object
  class << self
    alias _hyper_operation_original_method_missing method_missing

    def method_missing(name, *args, &block)
      if name =~ /^[A-Z]/
        scopes = self.name.to_s.split('::').inject([Module]) do |nesting, next_const|
          nesting + [nesting.last.const_get(next_const)]
        end.reverse
        #cant use const_defined? on server because it wont invoke rails auto loading
        scope = scopes.detect { |s| s.const_get(name) rescue nil }
        const = scope.const_get(name) if scope
      end
      _hyper_operation_original_method_missing(name, *args, &block) unless const.is_a?(Class) && const < Hyperloop::Operation
      const.send(:run, *args)
    end
  end

  alias _hyper_operation_original_method_missing method_missing

  def method_missing(name, *args, &block)
    if name =~ /^[A-Z]/
      first = self.is_a?(Module) || self.is_a?(Class) ? self.name : self.class.name
      scopes = first.to_s.split('::').inject([Module]) do |nesting, next_const|
        nesting + [nesting.last.const_get(next_const)]
      end.reverse
      #cant use const_defined? on server because it wont invoke rails auto loading
      scope = scopes.detect { |s| s.const_get(name) rescue nil }
      const = scope.const_get(name) if scope
    end
    _hyper_operation_original_method_missing(name, *args, &block) unless const.is_a?(Class) && const < Hyperloop::Operation
    const.send(:run, *args)
  end
end
