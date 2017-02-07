module React
  module IsomorphicHelpers
    def self.load_context(ctx, controller, name = nil)
      @context = Context.new("#{controller.object_id}-#{Time.now.to_i}", ctx, controller, name)
    end
  end
end
