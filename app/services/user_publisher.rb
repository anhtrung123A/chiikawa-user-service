class UserPublisher
  EXCHANGE_NAME = "user.events"

  def self.publish_user_event(user, event)
    exchange = $channel.fanout(EXCHANGE_NAME)
    payload = { id: user.id, email: user.email, full_name: user.full_name, line_user_id: user.line_user_id, dob: user.dob, event: event }.to_json
    exchange.publish(payload)
    Rails.logger.info("Published user_confirmed event: #{payload}")
  end
end
