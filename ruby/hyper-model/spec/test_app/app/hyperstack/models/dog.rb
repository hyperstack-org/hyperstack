require_relative 'pet'

class Dog < Pet
  has_many :bones
end
