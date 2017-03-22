# Interface to the Lolex package running on the client side
# Below we will monkey patch Timecop to call these methods
class Lolex
  class << self
    def init(page, client_time_zone, resolution)
      @capybara_page = page
      @resolution = resolution || 10
      @client_time_zone = client_time_zone
      run_pending_evaluations
      @initialized = true
    end

    def initialized?
      @initialized
    end

    def push(mock_type, *args)
      scale = if mock_type == :freeze
                0
              elsif mock_type == :scale
                args[0]
              else
                1
              end
      evaluate_ruby do
        "Lolex.push('#{time_string_in_zone}', #{scale}, #{@resolution})"
      end
    end

    def pop
      evaluate_ruby { 'Lolex.pop' }
    end

    def unmock
      evaluate_ruby { "Lolex.unmock('#{time_string_in_zone}', #{@resolution})" }
    end

    def restore
      evaluate_ruby { 'Lolex.restore' }
    end

    private

    def time_string_in_zone
      Time.now.in_time_zone(@client_time_zone).strftime('%Y/%m/%d %H:%M:%S %z')
    end

    def pending_evaluations
      @pending_evaluations ||= []
    end

    def evaluate_ruby(&block)
      if @capybara_page
        @capybara_page.evaluate_ruby(yield)
      else
        pending_evaluations << block
      end
    end

    def run_pending_evaluations
      return if pending_evaluations.empty?
      @capybara_page.evaluate_ruby(pending_evaluations.collect do |block|
        block.call
      end.join("\n"))
      @pending_evaluations ||= []
    end
  end
end

require 'timecop'

# Monkey patches to call our Lolex interface
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
