require 'hyper-react'
require 'user'
require 'synchromesh'

class TodosComponent

  include React::Component

  export_component

  #optional_param :initial_user_email
  required_param :users, type: [User]
  #define_state :users

  before_mount do
    # `debugger`
    nil
    #users! [User.find_by_id(1), User.find_by_id(2), User.find_by_id(3)]
  end

  after_mount do
    #puts "after mount"
    # `debugger`
    nil
  end

  backtrace :on

  after_update do
    #puts "after update"
    if user
      #  `debugger`
      nil
    end
  end

  def render
    div do
      TodosMainComponent(users: users)
    end.hide_while_loading
  end

end
