module Hyperstack
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('production')
  end
end
