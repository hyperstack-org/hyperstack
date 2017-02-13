class HyperOperation

  class << self
    def on_dispatch(&block)
      receivers << block
    end

    def receivers
      @receivers ||= []
    end

    def dispatch(*hashes)
      receivers.each do |receiver|
        receiver.call _params_wrapper.dispatch_params(params, hashes)
      end
    end
  end

  def dispatch(*hashes)
    self.class.receivers.each do |receiver|
      receiver.call self.class._params_wrapper.dispatch_params(params, hashes)
    end
  end
end
