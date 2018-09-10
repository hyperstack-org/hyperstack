class HomeController < ApplicationController
  def show
    render_component 'TestComp'
  end
end
