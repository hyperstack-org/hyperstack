class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  regulate_scope all: true
end
