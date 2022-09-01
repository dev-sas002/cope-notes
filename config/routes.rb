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

  get '/up', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }
end
