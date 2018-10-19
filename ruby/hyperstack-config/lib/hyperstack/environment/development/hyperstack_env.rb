module Hyperstack
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('development')
  end
end
