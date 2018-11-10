Rails.application.routes.draw do
  mount Hyperstack::Engine => '/hyperstack'
  get '/(*other)', to: 'hyperstack#app'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
