class PasswordRecoveryMailer < ApplicationMailer
  def password_recovery_otp(user, otp)
    @user = user
    @otp = otp
    mail(to: @user.email, subject: "Your 6-digit OTP for password reset")
  end
end
