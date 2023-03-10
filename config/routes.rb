Rails.application.routes.draw do
  resources :messages, only: [:create, :new, :index]
  get '/messages/:mailbox/:msgid', to: 'messages#show', as: "message"
  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
