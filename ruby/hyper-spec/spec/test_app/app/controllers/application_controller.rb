class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  class << self
    attr_accessor :acting_user
  end

  def acting_user
    ApplicationController.acting_user
  end
end
