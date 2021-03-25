class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  # allow remote access to all scopes - i.e. you can count or get a list of ids
  # for any scope or relationship
  ApplicationRecord.regulate_scope :all unless Hyperstack.env.production?
end
