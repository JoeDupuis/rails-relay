Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :servers

  get "up" => "rails/health#show", as: :rails_health_check

  root "servers#index"
end
