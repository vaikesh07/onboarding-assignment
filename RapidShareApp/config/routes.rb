Rails.application.routes.draw do
  # This line creates all the necessary Devise routes, including the one for logging out.
  devise_for :users

  # This sets up the root pages depending on login status
  devise_scope :user do
    authenticated :user do
      root 'user_files#index', as: :authenticated_root
    end

    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  # Your application's routes
  get 'dashboard', to: 'user_files#index'
  resources :user_files, only: [:new, :create, :destroy] do
    member do
      patch 'share'
      get 'download'
    end
  end

  get 'shared/:token', to: 'user_files#shared', as: 'shared_file'
  get 'download/shared/:token', to: 'user_files#public_download', as: 'public_download'
end