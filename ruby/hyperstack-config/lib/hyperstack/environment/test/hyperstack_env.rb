module Hyperstack
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('test')
  end
end
