class HyperOperation
  class << self

    def run(*args)
      instance = (respond_to?(:execute) ? self : new)
      instance.instance_exec(_params_wrapper) do |params_wrapper|
        @raw_inputs, @params, @errors = params_wrapper.process_params(args)
        if has_errors?
          Promise.new.reject(ValidationException.new(@errors))
        else
          validate
          result = execute
          result = Promise.new.resolve(result) unless result.is_a? Promise
          result
        end
      end
    rescue Exception => e
      Promise.new.reject(e)
    end

    def then(*args, &block)
      run(*args).then(&block)
    end

    def has_errors?
      !@errors.nil?
    end

    def params
      @params
    end

    protected

    def validate
      # Meant to be overridden
    end
  end

  def has_errors?
    !@errors.nil?
  end

  def params
    @params
  end

  protected

  def validate
    # Meant to be overridden
  end

  def execute
    dispatch
  end
end
