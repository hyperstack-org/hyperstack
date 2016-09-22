class Word < ApplicationRecord

  def <=>(b)
    text.downcase <=> b.text.downcase
  end

  scope :sorted, -> { order('LOWER(text) ASC')},
        sync: -> (r, collection) { !collection.push(r).sort! }

end
