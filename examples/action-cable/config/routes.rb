Rails.application.routes.draw do
  get 'test', to: 'test#app'
  mount Hyperloop::Engine => '/rr'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
