class TestController < ApplicationController
  def app
    render inline: 'hello', :layout => "application"
  end
end
