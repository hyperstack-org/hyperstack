module Hyperloop
  # Allows interactive systems to reset context to the state at boot. Any
  # modules or classes that set context instance variables to hold things like
  # call backs should use Hyperloop::Context.set_var(self, :@var_name) { .... }
  # the provided block will be rerun and the instance variable re-initialized
  # when the reset! method is called
  module Context
    # pass self, an instance var name (symbol) and a block
    # if reset! has been called, then record the var and block for future resets
    # then if var is currently empty it will be initialized with block
    def self.set_var(ctx, var, &block)
      @context_hash[ctx] ||= [var, block] if @context_hash
      ctx.instance_variable_get(var) || ctx.instance_variable_set(var, yield)
    end

    def self.reset!(reboot = true)
      # if @context_hash is already initialized then reset all the instance
      # vars using their corresponding blocks.  Otherwise initialize
      # @context_hash.
      if @context_hash
        @context_hash.each do |context, var_and_block|
          var, block = var_and_block
          context.instance_variable_set(var, block.call)
        end
        Hyperloop::Application::Boot.run if reboot
      else
        @context_hash = {}
      end
    end
  end
end
