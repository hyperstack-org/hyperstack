module Hyperstack
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('staging')
  end
end
