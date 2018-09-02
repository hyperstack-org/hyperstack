module Hyperloop
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('development')
  end
end
