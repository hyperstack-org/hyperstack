class Date
  alias broken_equals ==
  def ==(other)
    return false unless other.is_a?(Date)
    broken_equals(other)
  end
end

class Time
  alias broken_equals ==
  def ==(other)
    return false unless other.is_a?(Time)
    broken_equals(other)
  end
end

begin
  JSON.parse("test")
rescue Exception => e
  JSON.class_eval do
    class << self
      alias old_parse parse
    end
    def self.parse(*args, &block)
      old_parse *args, &block
    rescue Exception => e
      raise StandardError.new e.message
    end
  end unless e.is_a? StandardError
end

class Set
  def &(enum)
    n = self.class.new
    enum.each { |o| n.add(o) if include?(o) }
    n
  end
  alias intersection &
end unless Set.method_defined? :intersection
