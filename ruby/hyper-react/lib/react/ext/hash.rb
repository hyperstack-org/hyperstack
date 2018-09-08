class Hash
  def shallow_to_n
    hash = `{}`
    self.each do |key, value|
       `hash[#{key}] = #{value}`
    end
    hash
  end
end
