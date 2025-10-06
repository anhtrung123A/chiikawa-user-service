class Api::V1::TokenController < ApplicationController
  include ActionController::Cookies
  include CookiesModifier

  def refresh
    refresh_token = params[:refresh_token] || cookies.signed[:refresh_token]

    if refresh_token
      new_jwt = RefreshTokenService.issue_access_token(refresh_token)
      render json: { access_token: new_jwt }, status: :ok
    else
      render json: { error: "missing refresh token" }, status: :bad_request
    end
  rescue RefreshTokenService::InvalidRefreshTokenError => e
    render json: { error: e.message }, status: :unauthorized
  end
end
