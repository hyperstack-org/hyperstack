module Hyperstack
  module Transport
    class WebSocket
      CONNECTING  = 0
      OPEN        = 1
      CLOSING     = 2
      CLOSED      = 3

      class SendError < StandardError; end

      def initialize(url, protocols = nil)
        @native_websocket = if protocols
                              `new WebSocket(url, protocols)`
                            else
                              `new WebSocket(url)`
                            end
      end

      def close
        @native_websocket.JS.close
      end

      def onclose(&block)
        @native_websocket.JS[:onclose] = `function(event) { block.$call(event); }`
      end

      def onerror(&block)
        @native_websocket.JS[:onerror] = `function(event) { block.$call(event); }`
      end

      def onmessage(&block)
        @native_websocket.JS[:onmessage] = `function(event) { block.$call(event); }`
      end

      def onopen(&block)
        @native_websocket.JS[:onopen] = `function(event) { block.$call(event); }`
      end

      def protocol
        @native_websocket.JS[:protocol]
      end

      def ready_state
        @native_websocket.JS[:readyState]
      end

      def send(data)
        case ready_state
        when OPEN then @native_websocket.JS.send(data)
        when CONNECTING then send_when_ready(data)
        when CLOSING then raise SendError.new('Cant send, still connection cosing!')
        when CLOSED then raise SendError.new('Cant send, still connection cosed!')
        end
      end

      def send_when_ready(data)
        case ready_state
        when OPEN then @native_websocket.JS.send(data)
        when CONNECTING then _delay { send_when_ready(data) }
        when CLOSING then raise SendError.new('Cant send, still connection cosing!')
        when CLOSED then raise SendError.new('Cant send, still connection cosed!')
        end
      end

      private

      def _delay(&block)
        `setTimeout(#{block.to_n}, 10)`
      end
    end
  end
end
