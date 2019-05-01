module Kernel
  def pause(s, &block)
    Promise.new.tap { |p| after(s) { p.resolve(*(block && [block.call])) }}
  end
  alias busy_sleep sleep
  alias sleep pause
end
