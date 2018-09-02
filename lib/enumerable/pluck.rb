# Add pluck to enumerable... its already done for us in rails 5+
module Enumerable
  def pluck(key)
    map { |element| element[key] }
  end
end unless Enumerable.method_defined? :pluck
