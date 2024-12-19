Rails.application.routes.draw do
  root 'pages#index'

  get 'play', to: 'pages#game'
  post 'command', to: 'pages#receive_command'
  namespace :pages do
    post 'login'
    get 'logout'
  end

  get 'characters', to: 'characters#index'
end
