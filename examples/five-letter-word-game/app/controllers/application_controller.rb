User # force User Model to load so we can get the policies up!

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def acting_user
    session.delete 'hyperloop-dummy-init' unless session.id
    User.find(session.id)
  end

end
