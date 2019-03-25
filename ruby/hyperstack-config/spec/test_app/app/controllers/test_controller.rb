class TestController < ActionController::Base
  def app
    render inline: 'hello', :layout => "application"
  end
end
