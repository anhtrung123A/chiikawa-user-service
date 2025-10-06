# app/jobs/send_confirmation_email_job.rb
class SendConfirmationEmailJob < ApplicationJob
  queue_as :mailers

  def perform(user_id)
    user = User.find(user_id)
    # Directly deliver the Devise mailer, don't call send_confirmation_instructions again
    Devise::Mailer.confirmation_instructions(user, user.confirmation_token).deliver_now
  end
end
