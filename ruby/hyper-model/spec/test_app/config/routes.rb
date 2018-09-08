Rails.application.routes.draw do
  mount Hyperloop::Engine => "/hyperloop_engine"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "home#show"
end
