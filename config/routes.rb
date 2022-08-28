# frozen_string_literal: true

require 'sidekiq/web'
Sidekiq::Web.app_url = '/'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  # letter_opener only captures mail in development; mounting it anywhere else
  # would expose delivered mail without authentication.
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  namespace :api do
    namespace :v1 do
      resources :subscribers, except: %i[new edit]
      resources :messages, except: %i[new edit]
      get 'deliveries/stats', to: 'deliveries#stats'
    end
  end

  get 'unsubscribe/:token', to: 'unsubscribes#show', as: :unsubscribe
  post 'unsubscribe/:token', to: 'unsubscribes#create'

  # 200 when the app boots without raising, 500 otherwise; used by the healthcheck.
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
