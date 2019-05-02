# from Rails 6.0 activesupport.  Remove once defined by Opal activesupport
module Enumerable
  INDEX_WITH_DEFAULT = Object.new
  private_constant :INDEX_WITH_DEFAULT
  def index_with(default = INDEX_WITH_DEFAULT)
    if block_given?
      result = {}
      each { |elem| result[elem] = yield(elem) }
      result
    elsif default != INDEX_WITH_DEFAULT
      result = {}
      each { |elem| result[elem] = default }
      result
    else
      to_enum(:index_with) { size if respond_to?(:size) }
    end
  end
end
