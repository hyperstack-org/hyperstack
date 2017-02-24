class HomeController < ApplicationController
  def chat
    render_component "::Chat"
  end
end
