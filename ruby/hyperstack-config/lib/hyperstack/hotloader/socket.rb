require 'native'
require 'io/writable'

module Hyperstack

  class Hotloader

    # Code taken from opal browser, did not want to force an opal-browser dependency
    #
    # A {Socket} allows the browser and a server to have a bidirectional data
    # connection.
    #
    # @see https://developer.mozilla.org/en-US/docs/Web/API/WebSocket
    class Socket
      def self.supported?
        Browser.supports? :WebSocket
      end

      include Native::Wrapper
      include IO::Writable

      def on(str, &block)
        puts "putting #{str}"
        b =  block
        cmd = "foo.on#{str} = #{b}"
        puts cmd
        `#{cmd}`
        # `foo.on#{str} = #{b}`
      end
      # include DOM::Event::Target

      #    target {|value|
      #Socket.new(value) if Native.is_a?(value, `window.WebSocket`)
      #  }

      # Create a connection to the given URL, optionally using the given protocol.
      #
      # @param url [String] the URL to connect to
      # @param protocol [String] the protocol to use
      #
      # @yield if the block has no parameters it's `instance_exec`d, otherwise it's
      #        called with `self`
      def initialize(url, protocol = nil, &block)
        if native?(url)
          super(url)
        elsif protocol
          super(`new window.WebSocket(#{url.to_s}, #{protocol.to_n})`)
        else
          super(`new window.WebSocket(#{url.to_s})`)
        end

        if block.arity == 0
          instance_exec(&block)
        else
          block.call(self)
        end if block
      end

      # @!attribute [r] protocol
      # @return [String] the protocol of the socket
      alias_native :protocol

      # @!attribute [r] url
      # @return [String] the URL the socket is connected to
      alias_native :url

      # @!attribute [r] buffered
      # @return [Integer] the amount of buffered data.
      alias_native :buffered, :bufferedAmount

      # @!attribute [r] type
      # @return [:blob, :buffer, :string] the type of the socket
      def type
        %x{
        switch (#@native.binaryType) {
          case "blob":
            return "blob";

          case "arraybuffer":
            return "buffer";

          default:
            return "string";
        }
      }
      end

      # @!attribute [r] state
      # @return [:connecting, :open, :closing, :closed] the state of the socket
      def state
        %x{
        switch (#@native.readyState) {
          case window.WebSocket.CONNECTING:
            return "connecting";

          case window.WebSocket.OPEN:
            return "open";

          case window.WebSocket.CLOSING:
            return "closing";

          case window.WebSocket.CLOSED:
            return "closed";
        }
      }
      end

      # @!attribute [r] extensions
      # @return [Array<String>] the extensions used by the socket
      def extensions
        `#@native.extensions`.split(/\s*,\s*/)
      end

      # Check if the socket is alive.
      def alive?
        state == :open
      end

      # Send data to the socket.
      #
      # @param data [#to_n] the data to send
      def write(data)
        `#@native.send(#{data.to_n})`
      end

      # Close the socket.
      #
      # @param code [Integer, nil] the error code
      # @param reason [String, nil] the reason for closing
      def close(code = nil, reason = nil)
        `#@native.close(#{code.to_n}, #{reason.to_n})`
      end
    end

  end
end
