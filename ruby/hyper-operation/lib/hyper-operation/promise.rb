# Caution.  For now Hyperstack maintains its own copy of the Promise class.
# Eventually the diff between hyperstacks version and the official Opal version
# should be put into a PR.

# A key feature add is the Fail Exception class which is simply there to allow
# a `always` block to reject without raising an error.  To use this see the run.rb
# module.

# Also see exception! method for the part of the code that detects the Fail exception.

# See https://github.com/opal/opal/issues/1967 for details.

class Promise
  def self.value(value)
    new.resolve(value)
  end

  def self.error(value)
    new.reject(value)
  end

  def self.when(*promises)
    When.new(promises)
  end

  class Fail < StandardError
    attr_reader :result
    def initialize(result)
      @result = result
    end
  end

  attr_reader :error, :prev, :next

  def initialize(action = {})
    @action = action

    @realized  = false
    @exception = false
    @value     = nil
    @error     = nil
    @delayed   = false

    @prev = nil
    @next = []
  end

  def value
    if Promise === @value
      @value.value
    else
      @value
    end
  end

  def act?
    @action.has_key?(:success) || @action.has_key?(:always)
  end

  def action
    @action.keys
  end

  def exception?
    @exception
  end

  def realized?
    !!@realized
  end

  def resolved?
    @realized == :resolve
  end

  def rejected?
    @realized == :reject
  end

  def pending?
    !realized?
  end

  def ^(promise)
    promise << self
    self    >> promise

    promise
  end

  def <<(promise)
    @prev = promise

    self
  end

  def >>(promise)
    @next << promise

    if exception?
      promise.reject(@delayed[0])
    elsif resolved?
      promise.resolve(@delayed ? @delayed[0] : value)
    elsif rejected?
      if !@action.has_key?(:failure) || Promise === (@delayed ? @delayed[0] : @error)
        promise.reject(@delayed ? @delayed[0] : error)
      elsif promise.action.include?(:always)
        promise.reject(@delayed ? @delayed[0] : error)
      end
    end

    self
  end

  def resolve(value = nil)
    if realized?
      raise ArgumentError, 'the promise has already been realized'
    end

    if Promise === value
      return (value << @prev) ^ self
    end

    begin
      if block = @action[:success] || @action[:always]
        value = block.call(value)
      end

      resolve!(value)
    rescue Exception => e
      exception!(e)
    end

    self
  end

  def resolve!(value)
    @realized = :resolve
    @value    = value

    if @next.any?
      @next.each { |p| p.resolve(value) }
    else
      @delayed = [value]
    end
  end

  def reject(value = nil)
    if realized?
      raise ArgumentError, 'the promise has already been realized'
    end

    if Promise === value
      return (value << @prev) ^ self
    end

    begin
      if block = @action[:failure] || @action[:always]
        value = block.call(value)
      end

      if @action.has_key?(:always)
        resolve!(value)
      else
        reject!(value)
      end
    rescue Exception => e
      exception!(e)
    end

    self
  end

  def reject!(value)
    @realized = :reject
    @error    = value

    if @next.any?
      @next.each { |p| p.reject(value) }
    else
      @delayed = [value]
    end
  end

  def exception!(error)
    # If the error is a Promise::Fail, then
    # the error becomes the error.result value
    # this allows code to raise an error on an
    # object that is not an error.
    if error.is_a? Promise::Fail
      error = error.result
    else
      @exception = true
    end
    reject!(error)
  end

  def then(&block)
    self ^ Promise.new(success: block)
  end

  def then!(&block)
    there_can_be_only_one!
    self.then(&block)
  end

  alias do then
  alias do! then!

  def fail(&block)
    self ^ Promise.new(failure: block)
  end

  def fail!(&block)
    there_can_be_only_one!
    fail(&block)
  end

  alias rescue fail
  alias catch fail
  alias rescue! fail!
  alias catch! fail!

  def always(&block)
    self ^ Promise.new(always: block)
  end

  def always!(&block)
    there_can_be_only_one!
    always(&block)
  end

  alias finally always
  alias ensure always
  alias finally! always!
  alias ensure! always!

  def trace(depth = nil, &block)
    self ^ Trace.new(depth, block)
  end

  def trace!(*args, &block)
    there_can_be_only_one!
    trace(*args, &block)
  end

  def there_can_be_only_one!
    if @next.any?
      raise ArgumentError, 'a promise has already been chained'
    end
  end

  def inspect
    result = "#<#{self.class}(#{object_id})"

    if @next.any?
      result += " >> #{@next.inspect}"
    end

    if realized?
      result += ": #{(@value || @error).inspect}>"
    else
      result += ">"
    end

    result
  end

  class Trace < self
    def self.it(promise)
      current = []

      if promise.act? || promise.prev.nil?
        current.push(promise.value)
      end

      if prev = promise.prev
        current.concat(it(prev))
      else
        current
      end
    end

    def initialize(depth, block)
      @depth = depth

      super success: proc {
        trace = Trace.it(self).reverse
        trace.pop

        if depth && depth <= trace.length
          trace.shift(trace.length - depth)
        end

        block.call(*trace)
      }
    end
  end

  class When < self
    def initialize(promises = [])
      super()

      @wait = []

      promises.each {|promise|
        wait promise
      }
    end

    def each(&block)
      raise ArgumentError, 'no block given' unless block

      self.then {|values|
        values.each(&block)
      }
    end

    def collect(&block)
      raise ArgumentError, 'no block given' unless block

      self.then {|values|
        When.new(values.map(&block))
      }
    end

    def inject(*args, &block)
      self.then {|values|
        values.reduce(*args, &block)
      }
    end

    alias map collect

    alias reduce inject

    def wait(promise)
      unless Promise === promise
        promise = Promise.value(promise)
      end

      if promise.act?
        promise = promise.then
      end

      @wait << promise

      promise.always {
        try if @next.any?
      }

      self
    end

    alias and wait

    def >>(*)
      super.tap {
        try
      }
    end

    def try
      if @wait.all?(&:realized?)
        if promise = @wait.find(&:rejected?)
          reject(promise.error)
        else
          resolve(@wait.map(&:value))
        end
      end
    end
  end
end
