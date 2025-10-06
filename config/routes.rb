Rails.application.routes.draw do
  devise_for :users,
             path: "api/v1/users",
             controllers: {
               sessions: "api/v1/users/sessions",
               registrations: "api/v1/users/registrations",
               confirmations: "api/v1/users/confirmations"
             },
             defaults: { format: :json }

  namespace :api do
    namespace :v1 do
      post "/token/refresh", to: "token#refresh"
      resources :addresses
    end
  end
end
