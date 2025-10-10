class Api::V1::Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      UserPublisher.publish_user_event(resource, "user_confirmed")
      redirect_to "http://localhost:5173/login?message=Your%20account%20has%20been%20successfully%20confirmed", allow_other_host: true
    else
      redirect_to "https://google.com?error=#{CGI.escape(resource.errors.full_messages.join(', '))}", allow_other_host: true
    end
  end

  private

  def respond_with(resource, _opts = {})
    if resource.errors.empty?
      render json: { message: "Your account has been confirmed." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
