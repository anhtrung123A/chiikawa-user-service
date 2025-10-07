class Api::V1::PasswordRecoveryController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    if user
      ttl = get_existing_otp_ttl(user.email)
      if ttl > 0
        ttl_text = ttl.to_s + (ttl == 1 ? " second" : " seconds")
        render json: { message: "Please wait #{ttl_text} before requesting a new OTP" }, status: :ok
      else
        otp = generate_recovery_otp(user.email)
        PasswordRecoveryMailer.password_recovery_otp(user, otp).deliver_later
        render json: { message: "OTP sent to your email" }, status: :ok
      end
    else
      render json: { error: "Email not found" }, status: :ok
    end
  end

  def verify
    if verify_recovery_otp(params[:email], params[:otp])
      render json: { message: "success", token: generate_recovery_session_token_for(params[:email]) }, status: :ok
    else
      render json: { error: "OTP is invalid or expired" }, status: :ok
    end
  end

  def recover_password
    email = params[:email]
    token = params[:token]
    new_password = params[:password]
    password_confirmation = params[:password_confirmation]

    unless verify_recovery_session_token(email, token)
      return render json: { error: "Session token is invalid or expired" }, status: :unauthorized
    end

    user = User.find_by(email: email)
    unless user
      return render json: { error: "User not found" }, status: :not_found
    end

    if new_password.blank? || password_confirmation.blank?
      return render json: { error: "Password and confirmation are required" }, status: :bad_request
    end

    if new_password != password_confirmation
      return render json: { error: "Passwords do not match" }, status: :unprocessable_entity
    end

    if user.valid_password?(new_password)
      return render json: { error: "New password cannot be the same as the current password" }, status: :unprocessable_entity
    end

    if user.update(password: new_password)
      $redis.del("recovery_session_token:#{email}")
      render json: { message: "Password has been successfully updated" }, status: :ok
    else
      render json: { error: "Failed to update password", details: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def generate_recovery_otp(email)
    otp = rand(100000..999999).to_s
    key = "recovery_otp:#{email}"
    $redis.setex(key, 3.minutes.to_i, otp)
    otp
  end

  def verify_recovery_otp(email, otp)
    key = "recovery_otp:#{email}"
    stored_otp = $redis.get(key)
    return false unless stored_otp && stored_otp == otp
    $redis.del(key)
    true
  end

  def verify_recovery_session_token(email, token)
    key = "recovery_session_token:#{email}"
    stored_token = $redis.get(key)
    return false unless stored_token && stored_token == token
    true
  end

  def generate_recovery_session_token_for(email)
    key = "recovery_session_token:#{email}"
    token =  SecureRandom.urlsafe_base64(64)
    $redis.setex(key, 15.minutes.to_i, token)
    token
  end

  def get_existing_otp_ttl(email)
    key = "recovery_otp:#{email}"
    $redis.ttl(key)
  end
end
