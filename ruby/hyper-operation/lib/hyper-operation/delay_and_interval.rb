module Kernel
  def every(time, &block)
    Thread.new { loop { sleep time; block.call }}
  end

  def after(time, &block)
    Thread.new { sleep time; block.call }
  end
end
