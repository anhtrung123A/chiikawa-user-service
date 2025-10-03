Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations'
             },
             defaults: { format: :json }

  # Example protected resource
  namespace :api do
    namespace :v1 do
      get 'profile', to: 'profiles#show'
    end
  end
end
