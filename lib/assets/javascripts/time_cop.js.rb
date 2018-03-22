if RUBY_ENGINE == 'opal'
  require 'lolex'
  require 'time'

  # Wrap the Lolex js package
  class Lolex
    class << self
      def stack
        @stack ||= []
      end

      def push(time, scale = 1, resolution = 10)
        puts "Lolex.push(#{time}, #{scale}, #{resolution})"
        time = Time.parse(time) if time.is_a? String
        stack << [Time.now, @scale, @resolution]
        update_lolex(time, scale, resolution)
      end

      def pop
        update_lolex(*stack.pop) unless stack.empty?
      end

      def unmock(time, resolution)
        push(time, 1, resolution)
        @backup_stack = stack
        @stack = []
      end

      def restore
        @stack = @backup_stack
        pop
      end

      def tick
        real_clock = `(new #{@lolex}['_Date']).getTime()`
        mock_clock = Time.now.to_f * 1000
        real_elapsed_time = real_clock - @real_start_time
        mock_elapsed_time = mock_clock - @mock_start_time

        ticks = real_elapsed_time * @scale - mock_elapsed_time

        `#{@lolex}.tick(#{ticks.to_i})`
        nil
      end

      def create_ticker
        return unless @scale && @scale > 0
        ticker = %x{
          #{@lolex}['_setInterval'].call(
            window,
            function() { #{tick} },
            #{@resolution}
          )
        }
        ticker
      end

      def update_lolex(time, scale, resolution)
        `#{@lolex}.uninstall()` && return if scale.nil?
        @mock_start_time = time.to_f * 1000

        if @lolex
          `#{@lolex}['_clearInterval'].call(window, #{@ticker})` if @ticker
          @real_start_time = `(new #{@lolex}['_Date']).getTime()`
          `#{@lolex}.tick(#{@mock_start_time - Time.now.to_f * 1000})`
        else
          @real_start_time = Time.now.to_f * 1000
          @lolex = `lolex.install({ now: #{@mock_start_time} })`
        end

        @scale = scale
        @resolution = resolution
        @ticker = create_ticker
        nil # must return nil otherwise we try to return a timer to server!
      end
    end
  end

else
  require 'timecop'

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
        @capybara_page.evaluate_ruby(pending_evaluations.collect(&:call).join("\n"))
        @pending_evaluations ||= []
      end
    end
  end

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
end
