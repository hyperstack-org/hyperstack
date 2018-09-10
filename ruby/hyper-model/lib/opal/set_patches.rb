class Set
  def &(enum)
    n = self.class.new
    enum.each { |o| n.add(o) if include?(o) }
    n
  end
  alias intersection &
end unless Set.method_defined? :intersection
