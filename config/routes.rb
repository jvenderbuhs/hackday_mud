Rails.application.routes.draw do
  root 'pages#index'

  get 'characters', to: 'characters#index'
end
