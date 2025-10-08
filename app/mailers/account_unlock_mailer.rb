class AccountUnlockMailer < ApplicationMailer
  def account_unlock_instruction(user)
    @user = user
    mail(to: @user.email, subject: "Follow the instruction to unlock your account")
  end
end
