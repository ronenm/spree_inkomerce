Spree::Core::Engine.routes.draw do
  get '/ink/success', to: 'inkomerce#success', as: :ink_success
  get '/ink/cancel', to: 'inkomerce#cancel', as: :ink_cancel
  get '/ink/negotiate', to: 'inkomerce#negotiate', as: :ink_negotiate
  
  namespace :admin do
    get '/inkomerce_store', to: "inkomerce_store#edit"
    get '/inkomerce_store/renew_token', to: "inkomerce_store#renew_token"
    put '/inkomerce_store', to: "inkomerce_store#update"
    put '/inkomerce_store/replace_token', to: "inkomerce_store#replace_token"
    
    resources :ink_buttons, only: [:index,:show]
    resources :ink_deals, only: [:index,:show] 
  end
end
