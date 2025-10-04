class Api::V1::Users::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.errors.empty?
      render json: { message: "Your account has been confirmed." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
