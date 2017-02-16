class HyperOperation
  class << self
    def run(*args)
      if @uplink_regulation && RUBY_ENGINE == 'opal'
        run_on_server(args)
      else
        new.instance_eval do
          @raw_inputs, @params, @errors = self.class._params_wrapper.process_params(args)
          if has_errors?
            Promise.new.reject(ValidationException.new(@errors))
          else
            validate
            result = execute
            result = Promise.new.resolve(result) unless result.is_a? Promise
            result
          end
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
    if self.class.respond_to? :execute
      self.class.execute *(self.class.method(:execute).arity.zero? ? [] : [self])
    else
      dispatch
    end
  end
end
