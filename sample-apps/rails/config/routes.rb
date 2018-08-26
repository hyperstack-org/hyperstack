Rails.application.routes.draw do
  root 'home#index'
  match '*all', to: 'home#index', via: [:get]
end
