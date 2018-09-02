module Hyperloop
  def self.env
    @environment ||= ActiveSupport::StringInquirer.new('production')
  end
end
