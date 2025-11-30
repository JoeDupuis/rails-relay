Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :servers do
    resource :connection, only: [ :create, :destroy ]
  end

  namespace :internal do
    namespace :irc do
      resources :connections, only: [ :create, :destroy ]
      resources :commands, only: [ :create ]
      resources :events, only: [ :create ]
      resource :status, only: [ :show ], controller: "status"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "servers#index"
end
