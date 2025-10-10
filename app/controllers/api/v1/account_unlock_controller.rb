class Api::V1::AccountUnlockController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    if user == nil 
      render json: { error: "user not found" }, status: :not_found
      return
    end
    if user.locked_at == nil && user.unlock_token == nil
      render json: { message: "user is not locked" }, status: :ok
      return
    end
    if user.update(unlock_token: SecureRandom.urlsafe_base64(64))
      AccountUnlockMailer.account_unlock_instruction(user).deliver_later
      render json: { message: "Unlock instruction email has been sent to your email" }, status: :ok
    else
      render json: { error: "Failed to create unlock token", details: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def unlock
    user_id = params[:user_id]
    unlock_token = params[:unlock_token]
    if user_id == nil || unlock_token == nil
      render json: { message: "bad format" }, status: :unprocessable_entity
      return
    end
    user = User.find_by(id: params[:user_id])
    if user == nil
      render json: { error: "user not found" }, status: :not_found
      return
    end
    if user.unlock_token != unlock_token
      render json: { error: "unlock token invalid" }, status: :unauthorized
      return
    end
    if user.update(locked_at: nil, unlock_token: nil)
      redirect_to "https://chiikawamarket.jp/en/account/login", allow_other_host: true
    else
      render json: { error: "Failed to unlock account", details: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end