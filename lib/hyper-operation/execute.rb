class HyperOperation
  class << self
    def run(*args)
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
    rescue Exception => e
      Promise.new.reject(e)
    end

    def then(*args, &block)
      run(*args).then(&block)
    end

  end

  def add_error(key, kind, message = nil)
    raise ArgumentError.new("Invalid kind") unless kind.is_a?(Symbol)

    @errors ||= ErrorHash.new
    @errors.tap do |errs|
      path = key.to_s.split(".")
      last = path.pop
      inner = path.inject(errs) do |cur_errors,part|
        cur_errors[part.to_sym] ||= ErrorHash.new
      end
      inner[last] = ErrorAtom.new(key, kind, :message => message)
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
