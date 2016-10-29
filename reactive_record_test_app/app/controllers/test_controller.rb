class TestController < ApplicationController
  
  def index
    render inline: "<%= react_component 'Test', {}, { prerender: !params[:no_prerender] } %>", layout: nil
  end
  
end