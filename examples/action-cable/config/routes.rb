Rails.application.routes.draw do
  mount ReactiveRecord::Engine => '/rr'
  get 'test', to: 'test#app'
end
