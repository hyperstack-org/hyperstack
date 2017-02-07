require 'timecop'

module HyperSpec
  class Timecop
    private

    def travel(mock_type, *args, &block)
      raise SafeModeException if Timecop.safe_mode? && !block_given?

      stack_item = TimeStackItem.new(mock_type, *args)

      stack_backup = @_stack.dup
      @_stack << stack_item

      Lolex.push(mock_type, *args)

      if block_given?
        begin
          yield stack_item.time
        ensure
          Lolex.pop
          @_stack.replace stack_backup
        end
      end
    end

    def return(&block)
      current_stack = @_stack
      current_baseline = @baseline
      unmock!
      yield
    ensure
      Lolex.restore
      @_stack = current_stack
      @baseline = current_baseline
    end

    def unmock! #:nodoc:
      @baseline = nil
      @_stack = []
      Lolex.unmock
    end
  end
end
