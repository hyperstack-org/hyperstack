class TestData

  def initialize(string, times)
    @string = string
    @times = times
  end

  attr_accessor :string
  attr_accessor :times

  def big_string
    puts "calling big_string #{string} * #{times}"
    string * times
  end

end

class User < ActiveRecord::Base

  def view_permitted?(attribute)
    return self == acting_user if acting_user
    super  # we call super to test if its there (just for the spec) not really the right way to do it, see comments or todo_items
  end

  has_many :todo_items
  has_many :comments
  has_many :commented_on_items, class_name: "TodoItem", through: :comments, source: :todo_item

  composed_of :address,  :class_name => 'Address', :constructor => :compose, :mapping => Address::MAPPED_FIELDS.map {|f| ["address_#{f}", f] }
  composed_of :address2, :class_name => 'Address', :constructor => :compose, :mapping => Address::MAPPED_FIELDS.map {|f| ["address2_#{f}", f] }

  composed_of :data, :class_name => 'TestData', :allow_nil => true, :mapping => [['data_string', 'string'], ['data_times', 'times']]

  enum test_enum: [:yes, :no]
  
  def name
    "#{first_name} #{last_name}"
  end

  # two examples of server side calculated attributes.  The second takes a parameter.
  # the first does not rely on an id, so can be used before the record is saved.

  def detailed_name
    s = "#{first_name[0]}. #{last_name}" rescue ""
    s += " - #{email}" if email
    s += " (#{todo_items.size} todo#{'s' if todo_items.size > 1})" if todo_items.size > 0
    s
  end unless RUBY_ENGINE == 'opal'

  def expensive_math(n)
    n*n
  end unless RUBY_ENGINE == 'opal'

  # this is also used for remote calculation in the aggregate test

  def verify_zip
    if address.zip =~ /^\d{5}$/
      address.zip
    end
  end unless RUBY_ENGINE == 'opal'

end

class User < ActiveRecord::Base

  def as_json(*args)
    {name: "bozo"}
  end

  validates :email, format: {with: /\@.+\./}, :allow_nil => true

  def name=(val)  # this is here to test ability to save changes to this type of psuedo attribute
    val = val.split(" ")
    self.first_name = val[0]
    self.last_name = val[1]
  end

end unless RUBY_ENGINE == 'opal'
