class Object
  def tap
    val = `self.$$is_boolean` ? self==true : self
    yield val
    val
  end
end
