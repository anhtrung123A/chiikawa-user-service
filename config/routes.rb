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
      patch "/addresses/set_default_address", to: "addresses#set_default_address"
      post "/users/unlock", to: "account_unlock#create"
      get "/users/unlock", to: "account_unlock#unlock", as: "unlock"
      get "/addresses/default_address", to: "addresses#show_default_address"
      resources :addresses
      resources :password_recovery, only: [ :create ]
      post "/auth/line", to: "line_auth#login_with_line"
      patch "/auth/line", to: "line_auth#link_with_line_account"
      post "/password_recovery/verify_otp", to: "password_recovery#verify"
      patch "/password_recovery/recover", to: "password_recovery#recover_password"
    end
  end
end
