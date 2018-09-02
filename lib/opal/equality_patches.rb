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
