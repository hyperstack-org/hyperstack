module Hyperloop
  module Console
    class DebugConsole < Hyperloop::Component
      param :application_window_id
      param :context
      param :title

      state history: [], scope: :shared
      state console_state: :waiting_for_code, scope: :shared

      class << self
        attr_accessor :application_window_id
        attr_accessor :context

        def console_id
          @console_id ||=
            (
              `sessionStorage.getItem('Hyperloop::Console::ConsoleId')` ||
              SecureRandom.uuid.tap { |id| `sessionStorage.setItem('Hyperloop::Console::ConsoleId', #{id})` }
            )
        end

        def ready!(code, compiled_code)
          @code_to_send = code
          mutate.error_message nil
          evaluate compiled_code if @code_to_send =~ /.\n$/
        end

        def evaluate(compiled_code)
          @code_to_send = @code_to_send[0..-2]
          mutate.history << {eval: @code_to_send}
          mutate.console_state :sending
          # if using actioncable with opal_hot_reloader the connection will close
          # so this hack will reopen the connection before sending the message.
          HTTP.get("#{`window.HyperloopEnginePath`}/server_up") do
            `#{Hyperloop.action_cable_consumer}.connection.open()` if Hyperloop.action_cable_consumer && `#{Hyperloop.action_cable_consumer}.connection.disconnected`
            Evaluate.run target_id: application_window_id, sender_id: console_id, context: context, string: compiled_code
          end
        end
      end

      after_mount do
        DebugConsole.application_window_id = params.application_window_id
        DebugConsole.context = params.context
        mutate.history(JSON.parse(`sessionStorage.getItem('Hyperloop::Console.history')` || '[]'))
        `document.title = #{params.title}`
        `window.scrollTo(window.scrollX, 99999)`

        Response.on_dispatch do |p|
          next unless p.target_id == DebugConsole.console_id
          mutate.console_state :waiting_for_code
          mutate.history << {p.kind => p.message}
          `sessionStorage.setItem('Hyperloop::Console.history', #{state.history.to_json})`
        end

      end

      after_update do
        `window.scrollTo(window.scrollX, 99999)`
      end

      render(DIV, style: { height: '100vh' }) do
        # the outer DIV is needed to set fill the window so mouse clicks anywhere
        # will go to the last line of the editor
        DIV(class: :card) do
          state.history.each do |item|
            CodeHistoryItem(item_type: item.first.first, value: item.first.last || '')
          end
          CodeEditor(history: state.history, context: params.context) unless state.console_state == :sending
        end.on(:mouse_down) do |e|
          CodeEditor.set_focus
          e.prevent_default
        end
      end
    end

    class CodeMirror < Hyperloop::Component

      attr_reader :editor

      after_mount do
        @editor = `CodeMirror(#{dom_node}, {
          value: #{@code.to_s},
          mode: 'text/x-ruby',
          matchBrackets: true,
          lineNumbers: false,
          indentUnit: 2,
          theme: 'github',
          readOnly: #{!!@read_only}
        })`
      end

      render(DIV)

    end

    class CodeHistoryItem < CodeMirror

      param :item_type
      param :value

      def format
        case params.item_type
        when :eval
          params.value
        when :exception
          format_lines("!!", params.value)
        when :result
          format_lines(">>", params.value)
        else
          format_lines("#{params.item_type}:", params.value)
        end
      end

      def format_lines(prefix, value)
        fill = prefix.gsub(/./, ' ')
        lines = value.split("\n")
        (["#{prefix} #{lines.shift}"]+lines.collect do |line|
          "#{fill} #{line}"
        end).join("\n")
      end

      def mark_response_lines
        return if params.item_type == :eval
        lines = params.value.split("\n")
        padding = [:exception, :result].include?(params.item_type) ? 3 : 2+params.item_type.to_s.length
        last_line = lines[-1] || ''
        `#{@editor}.markText({line: 0, ch: 0}, {line: #{lines.count-1}, ch: #{last_line.length+padding}}, {className: 'response-line'})`
      end

      before_mount do
        @code = format
        @read_only = true
      end

      after_mount do
        mark_response_lines
      end

      render do
        DIV {}.on(:mouse_down) { |e| e.stop_propagation }
      end

    end

    class CodeEditor < CodeMirror
      param :history
      param :context

      class << self
        attr_accessor :editor

        def set_focus
          editor.set_focus_at_end if editor
        end
      end

      before_mount do
        @history = params.history.collect { |item| item[:eval] }.compact + ['']
        @history_pos = @history.length-1
      end

      after_mount do
        `#{@editor}.on('change', #{lambda {on_change} })`
        `#{@editor}.on('keydown', #{lambda { |cm, e| on_key_down(cm, e) } })`
        `#{@editor}.focus()`
        self.class.editor = self
      end

      before_unmount do
        self.class.editor = nil
      end

      def move_history(n)
        @history[@history_pos] = `#{@editor}.getValue()`
        @history_pos += n
        text = @history[@history_pos]
        lines = text.split("\n")
        `#{@editor}.setValue(#{text})`

        after(0) do
          `window.scrollTo(window.scrollX, 99999)`
          `#{@editor}.setCursor({line: #{lines.count}, ch: #{(lines.last || '').length}})`
        end
      end

      def set_focus_at_end
        `#{@editor}.focus()`
        lines = `#{@editor}.getValue()`.split("\n")
        `#{@editor}.setCursor({line: #{lines.count}, ch: #{(lines.last || '').length}})`
      end


      def on_key_down(cm, e)
        if `e.metaKey` || `e.ctrlKey`
          return unless `e.keyCode` == 13
          `#{@editor}.setValue(#{@editor}.getValue()+#{"\n"})`
          #on_change
        elsif `e.key` == 'ArrowUp'
          move_history(-1) if @history_pos > 0
        elsif `e.key` == 'ArrowDown'
          move_history(1) if @history_pos < @history.length-1
        end
      end

      def mark_error(message)
        from, to, title = parse_error(message)
        @error = `#{@editor}.markText(#{from.to_n}, #{to.to_n}, {className: 'syntax-error', title: title})`
      end

      def parse_error(message)
        message = message.split("\n")
        position_info = message[3].split(':')
        last_line_number = `#{@editor}.lineCount()`
        last_line = `#{@editor}.getLine(last_line_number-1)`
        [
          {line: 0, ch: 0},
          {line: last_line_number, ch: last_line.length},
          message[2].split(':(file)')[0]
        ]
      end

      def clear_error
        `#{@error}.clear()` if @error
        @error = nil
      end

      def on_change
        clear_error
        code = `#{@editor}.getValue()`
        if params.context.empty?
          compiled_code = Opal.compile(code, irb: true)
        else
          compiled_code = Opal.compile("#{params.context}.instance_eval {#{code}}")
        end
        DebugConsole.ready!(code, compiled_code)
      rescue Exception => e
        mark_error(e.message)
      end

      render do
        DIV {}.on(:mouse_down) { |e| e.stop_propagation }
      end
    end

    Document.ready? do
      mount_point = Element["[data-react-class='React.TopLevelRailsComponent']"]
      mount_point.render do
        Hyperloop::Console::DebugConsole(JSON.parse(mount_point.attr('data-react-props'))[:render_params])
      end
    end
  end
end
