Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/authorisation_flow' => 'oauth#authorisation_flow', as: 'auth_flow'

  get '/native_authorisation_flow' => 'oauth#native_authorisation_flow', as: 'native_auth_flow'

  get '/' => "home#index"

  resources :callbacks, only: [:index] do
    collection do
      # get 'sign_up'
      # get 'login'
      get 'redirect'
      # put 'logout'
    end
  end
end
