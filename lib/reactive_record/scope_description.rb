module ReactiveRecord
  class ScopeDescription
  # Keeps track of the details (client side) of a scope.
  # The main point is to provide knowledge of what models
  # the scope is joined with.

    def initialize(model, scope_arg, joins_list = nil, &joins_block)
      scope_arg, joins_list = [joins_list, scope_arg] unless scope_arg.respond_to? :call
      @model = model
      @joins_list = if joins_list.nil?
                      [model]
                    elsif !joins_list.is_a?(Array)
                      []
                    elsif joins_list.empty?
                      joins_list
                    else
                      joins_list + [model]
                    end
      @joins_block = joins_block
    end

    def joins_with?(record, collection)
      included_in_list = @joins_list.detect { |klass| record.class == klass || record.class < klass }
      if @joins_block && (@joins_list.empty? || included_in_list)
        @joins_block.call(record, collection)
      elsif @joins_block.nil?
        !!included_in_list
      end
    end
  end
end
