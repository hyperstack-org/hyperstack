class HyperOperation 
end

class Object
  class << self
    alias _hyper_operation_original_method_missing method_missing

    def method_missing(name, *args, &block)
      if name =~ /^[A-Z]/
        scopes = self.name.to_s.split('::').inject([Module]) do |nesting, next_const|
          nesting + [nesting.last.const_get(next_const)]
        end.reverse
        scope = scopes.detect { |s| s.const_defined?(name) }
        const = scope.const_get(name) if scope
      end
      _hyper_operation_original_method_missing(name, *args, &block) unless const.is_a?(Class) && const < HyperOperation
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
      #binding.pry
      scope = scopes.detect { |s| s.const_defined?(name) }
      const = scope.const_get(name) if scope
    end
    _hyper_operation_original_method_missing(name, *args, &block) unless const.is_a?(Class) && const < HyperOperation
    const.send(:run, *args)
  end
end
