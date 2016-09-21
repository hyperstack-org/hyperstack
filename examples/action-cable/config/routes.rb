Rails.application.routes.draw do
  mount ReactiveRecord::Engine => '/rr'
  get 'test', to: 'test#app'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
