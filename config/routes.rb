Spree::Core::Engine.routes.draw do
  get '/ink/success', to: 'inkomerce#success', as: :ink_success
  get '/ink/cancel', to: 'inkomerce#cancel', as: :ink_cancel
  
  namespace :admin do
    get '/inkomerce_store', to: "inkmoerce_store#show", as: :inkomerce_store
    get '/inkomerce_store/new', to: "inkomerce_store#new", as: :new_inkomerce_store
    get '/inkomerce_store/edit', to: "inkomerce_store#edit", as: :edit_inkomerce_store
    post '/inkmoerce_store', to: "inkmoerce_store#create"
    put '/inkmoerce_store', to: "inkmoerce_store#update"
    
    resources :ink_buttons, only: [:index,:show]
    resources :ink_deals, only: [:index,:show] 
  end
end
