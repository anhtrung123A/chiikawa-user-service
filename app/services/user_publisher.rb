class UserPublisher
  EXCHANGE_NAME = "user.events"

  def self.publish_user_confirmed(user)
    exchange = $channel.fanout(EXCHANGE_NAME)
    payload = { id: user.id, email: user.email, event: "user_confirmed" }.to_json
    exchange.publish(payload)
    Rails.logger.info("Published user_confirmed event: #{payload}")
  end
end