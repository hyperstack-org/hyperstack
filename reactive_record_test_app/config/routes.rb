Rails.application.routes.draw do

  root :to => "home#index"
  match 'test', :to => "test#index", via: :get
  mount HyperMesh::Engine => "/rr"

end
