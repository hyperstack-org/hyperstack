# dummy user model... just creates an object that responds to #id and
# is equal to all other instances that have the the same id
class User
  def initialize(id)
    @id = id
  end

  def ==(other)
    other && id == other.id
  end

  def eql?(other)
    self == other
  end

  def self.find(id)
    new(id) if id
  end

  def hash
    id.hash
  end

  def id
    @id.to_s
  end
end
