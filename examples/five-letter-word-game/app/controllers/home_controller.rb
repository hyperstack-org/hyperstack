class HomeController < ApplicationController
  def app
    render_component "::App"
  end
end
