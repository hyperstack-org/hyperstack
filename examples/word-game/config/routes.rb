Rails.application.routes.draw do
  mount HyperMesh::Engine => '/rr'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
