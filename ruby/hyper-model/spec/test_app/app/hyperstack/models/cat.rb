require_relative 'pet'

class Cat < Pet
  has_many :scratching_posts
end
