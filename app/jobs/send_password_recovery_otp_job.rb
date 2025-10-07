class SendPasswordRecoveryOtpJob < ApplicationJob
  queue_as :mailers

  def perform(user, otp)
    PasswordRecoveryMailer.password_recovery_otp(user, otp).deliver_now
  end
end
