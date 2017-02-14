class TestController < ApplicationController
  def app
    if params[:no_prerender]
      render inline: "<%= react_component('App', {}, { prerender: false }) %>",
             layout: 'application'
    else
      render component: 'App', props: {}, layout: 'application'
    end
  end
end
