class ApplicationController < ActionController::Base
  #protect_from_forgery
  
  def acting_user
    cookies[:acting_user] and User.find_by_email(cookies[:acting_user])
  end
  
end
