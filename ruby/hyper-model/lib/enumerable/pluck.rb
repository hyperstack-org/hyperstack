# Add pluck to enumerable... its already done for us in rails 5+
module Enumerable
  def pluck(*keys)
    map { |element| keys.map { |key| element[key] } }
      .flatten(keys.count > 1 ? 0 : 1)
  end
end unless Enumerable.method_defined? :pluck
