class MyStore
  include Hyperstack::Component

  after_mount { puts "after_mount in MyStore" }
  
  def self.foo
    12
  end
end
