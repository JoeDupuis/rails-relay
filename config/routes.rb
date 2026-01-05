Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :notifications, only: [ :index, :update ]
  resources :servers do
    resource :connection, only: [ :create, :destroy ]
    resources :channels, only: [ :create ]
    resources :messages, only: [ :create ]
    resources :conversations, only: [ :create ]
  end

  resources :channels, only: [ :show, :update, :destroy ] do
    resources :messages, only: [ :create ]
    resources :uploads, only: [ :create ]
  end

  resources :conversations, only: [ :show ] do
    resources :messages, only: [ :create ], controller: "conversation/messages"
    resource :closure, only: [ :create ], controller: "conversation/closures"
  end

  resource :ison, only: [ :show ]

  namespace :internal do
    namespace :irc do
      resources :connections, only: [ :create, :destroy ]
      resources :commands, only: [ :create ]
      resources :events, only: [ :create ]
      resource :status, only: [ :show ], controller: "status"
      resource :ison, only: [ :show ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "configurations/android_v1" => "configurations#android_v1"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "servers#index"
end
