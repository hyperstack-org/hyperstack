module ReactiveRecord
  class ScopeDescription
  # Keeps track of the details (client side) of a scope.
  # The main point is to provide knowledge of what models
  # the scope is joined with.

    def initialize(name, model, joins_list, sync_proc)
      puts "initializing scope description: #{model}, #{joins_list}, #{sync_proc}"
      @name = name
      @model = model
      @joins_list = if joins_list.nil?
                      [model]
                    elsif joins_list == :all
                      [ActiveRecord::Base]
                    elsif joins_list.is_a?(Array)
                      joins_list + [model]
                    elsif joins_list.is_a?(Class) && joins_list < ActiveRecord::Base
                      [joins_list]
                    else
                      raise "Unknown scope option :joins => #{joins_list}, "\
                            "should be a model class, an array of classes or `:all`."
                    end
      unless @sync_proc.respond_to?(:call) || !@sync_proc
        raise "Scope option :sync must be a proc, false, or nil"
      end
      @sync_proc = sync_proc
    end

    def joins_with?(record, collection)

      if !@sync_proc || not_in_join_list(record)
        false
      elsif !@sync_proc.respond_to?(:call)
        true
      elsif @sync_proc.arity.abs >= 2
        @sync_proc.call(record, collection)
      else
        @sync_proc.call(record)
      end
    end

    def not_in_join_list(record)
      !@joins_list.detect do |klass|
        record.class == klass || record.class < klass
      end
    end

  end
end
