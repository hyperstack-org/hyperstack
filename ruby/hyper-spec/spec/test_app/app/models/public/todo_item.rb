class TodoItem < ActiveRecord::Base

  def view_permitted?(attribute)
    !acting_user or user_is? acting_user
  end

  def update_permitted?
    return true unless acting_user
    return only_changed? :comments unless user_is? acting_user
    true
  end

  belongs_to :user
  has_many :comments
  has_many :commenters, class_name: "User", through: :comments, source: :user
  belongs_to :comment # just so we can test an empty belongs_to relationship

  scope :find_string, ->(s) { where("title LIKE ? OR description LIKE ?", "%#{s}%", "%#{s}%") }

  scope :active, -> { where("title LIKE '%mitch%' OR description LIKE '%mitch%'")}
  # to_sync :active do |scope, record|
  #   if record.title =~ /mitch/ || record.description =~ /mitch/
  #     scope << record
  #   else
  #     scope.delete(record)
  #   end
  # end

  scope :important, -> { where("title LIKE '%another%' OR description LIKE '%another%'")}
  # to_sync(:important) {title =~ /another/ || description =~ /another/ }

  def virtual_user_first_name
    user.first_name
  end unless RUBY_ENGINE == 'opal'

end
