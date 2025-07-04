Rails.application.routes.draw do
  get 'user_files/index'
  get 'user_files/new'
  get 'user_files/create'
  get 'user_files/destroy'
  get 'user_files/download'
  get 'user_files/share'
  get 'user_files/shared'
  get 'sessions/new'
  get 'sessions/create'
  get 'sessions/destroy'
  get 'users/new'
  get 'users/create'
  get 'users/show'
  get 'users/edit'
  get 'users/update'
  root 'sessions#new' # Set login as the root page

  # User Registration
  get 'signup', to: 'users#new'
  post 'users', to: 'users#create'

  # User Sessions (Login/Logout)
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # User Profile
  get 'profile', to: 'users#show'
  get 'profile/edit', to: 'users#edit'
  patch 'profile', to: 'users#update'

  # File Dashboard
  get 'dashboard', to: 'user_files#index'

  # File Actions
  resources :user_files, only: [:new, :create, :destroy] do
    member do
      get 'download'
      patch 'share'
    end
  end

  # Public Shared Link
  get 'shared/:token', to: 'user_files#shared', as: 'shared_file'
  get 'download/shared/:token', to: 'user_files#public_download', as: 'public_download'
end