class Api::V1::Users::SessionsController < Devise::SessionsController
  include ActionController::Cookies
  include CookiesModifier
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    remember_me = ActiveModel::Type::Boolean.new.cast(
      params.dig(:user, :remember_me)
    )
    refresh_token = RefreshTokenService.create_for_user(resource, remember_me)
    cookies_sign(refresh_token, remember_me)
    render json: {
      message: "signed in successfully",
      user: { id: resource.id, email: resource.email, full_name: resource.full_name }
    }, status: :ok
  end

  def respond_to_on_destroy
    RefreshTokenService.delete_token(cookies.signed[:refresh_token])
    cookies_delete
    head :no_content
  end
end
