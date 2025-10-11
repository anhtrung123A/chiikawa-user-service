class Api::V1::LineWebhookController < ApplicationController
  protect_from_forgery with: :null_session if respond_to?(:protect_from_forgery)
  skip_before_action :authenticate_user_from_jwt

  def webhook
    body = request.body.read
    Rails.logger.info("LINE Webhook body: #{body}")

    json = JSON.parse(body)
    json["events"].each do |event|
      user_id = event.dig("source", "userId")
      message_text = event.dig("message", "text")

      Rails.logger.info("User ID: #{user_id}")
      Rails.logger.info("Message: #{message_text}")
    end

    render json: { status: "ok" }
  end
end
