Rails.application.routes.draw do

  root :to => "home#index"
  mount Hyperloop::Engine => "/rr"

end
