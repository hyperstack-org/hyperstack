::User # force User Model to load so we can get the policies up!
# Note is important to fully qualify the name otherwise rails gets
# confused when autoloading, and you will get an error when files changed
# during development. see http://stackoverflow.com/questions/17561697/argumenterror-a-copy-of-applicationcontroller-has-been-removed-from-the-module/23008837#23008837

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def acting_user
    session.delete 'hyperloop-dummy-init' unless session.id
    ::User.find(session.id)
  end

end
