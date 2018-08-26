Rails.application.routes.draw do
  root 'hyperloop#home'
  match '*all', to: 'hyperloop#home', via: [:get]
end
