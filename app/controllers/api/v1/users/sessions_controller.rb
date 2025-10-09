class Api::V1::Users::SessionsController < Devise::SessionsController
  include ActionController::Cookies
  include CookiesModifier
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    remember_me = ActiveModel::Type::Boolean.new.cast(
      params.dig(:user, :remember_me)
    )
    if resource.is_locked?
      render json: {
        message: "your account has been locked",
      }, status: :ok
      return
    end
    refresh_token = RefreshTokenService.create_for_user(resource, remember_me)
    cookies_sign(refresh_token, remember_me)
    resource.update_tracked_fields!(request)
    render json: {
      message: "signed in successfully",
      user: { id: resource.id, email: resource.email, full_name: resource.full_name, line_user_id: resource.line_user_id }
    }, status: :ok
  end

  def respond_to_on_destroy
    RefreshTokenService.delete_token(cookies.signed[:refresh_token])
    cookies_delete
    head :no_content
  end
end
