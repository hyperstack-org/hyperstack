module Hyperstack
  module AsyncSleep
    if RUBY_ENGINE == 'opal'
      def self.every(*args, &block)
        every(*args, &block)
      end

      def self.after(*args, &block)
        after(*args, &block)
      end
    else
      extend self

      def every(time, &block)
        Thread.new { loop { sleep time; block.call } }
      end

      def after(time, &block)
        Thread.new { sleep time; block.call }
      end
    end
  end
end
