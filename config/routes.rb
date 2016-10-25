ReactiveRecord::Engine.routes.draw do
  root :to => "reactive_record#fetch", via: :post
  match 'save', to: 'reactive_record#save', via: :post
  match 'destroy', to: 'reactive_record#destroy', via: :post
  match 'syncromesh-subscribe',        to: 'syncromesh#subscribe', via: :get
  match 'syncromesh-read/:subscriber', to: 'syncromesh#read',      via: :get
end
