module Hyperloop
  # Allows interactive systems to reset context to the state at boot. Any
  # modules or classes that set context instance variables to hold things like
  # call backs should use Hyperloop::Context.set_var(self, :@var_name) { .... }
  # the provided block will be rerun and the instance variable re-initialized
  # when the reset! method is called
  module Context
    # Replace @foo ||= ... with
    # Context.set_var(self, :@foo) { ... }
    # If reset! has been called then the instance variable will be record, and
    # will be reset on the next call to reset!
    # If you want to record the current value of the instance variable then set
    # force to true.
    def self.set_var(ctx, var, force: nil)
      inst_value_b4 = ctx.instance_variable_get(var)
      if @context && !@context[ctx].key?(var) && (force || !inst_value_b4)
        @context[ctx][var] = (inst_value_b4 && inst_value_b4.dup)
      end
      inst_value_b4 || ctx.instance_variable_set(var, yield)
    end

    def self.reset!(reboot = true)
      # if @context is already initialized then reset all the instance
      # vars using their corresponding blocks.  Otherwise initialize
      # @context.
      if @context
        @context.each do |ctx, vars|
          vars.each { |var, init| ctx.instance_variable_set(var, init) }
        end
        Hyperloop::Application::Boot.run if reboot
      else
        @context = Hash.new { |h, k| h[k] = {} }
      end
    end
  end
end
