module Hyperloop
  def self.env
    @environment ||= begin
      env = Rails.env if defined? Rails
      env ||= ENV['RACK_ENV']
      env = 'development' unless %w[development production test staging].include? env
      ActiveSupport::StringInquirer.new(env)
    end
  end
end
