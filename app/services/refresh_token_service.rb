class RefreshTokenService
  class InvalidRefreshTokenError < StandardError; end

  def self.create_for_user(user, remember_me)
    raw_token = SecureRandom.urlsafe_base64(64)
    token_hash = raw_token_encrypt(raw_token)
    ttl = remember_me ? 30.days.to_i : 24.hours.to_i
    $redis.setex("refresh_token:#{token_hash}", ttl, user.id)
    raw_token
  end

  def self.delete_token(raw_token)
    token_hash = raw_token_encrypt(raw_token)
    $redis.del("refresh_token:#{token_hash}")
  end

  def self.issue_access_token(refresh_token)
    user_id = get_user_id(refresh_token)
    unless user_id
      raise InvalidRefreshTokenError, "Invalid refresh token"
    end
    user = User.find_by(id: user_id)
    unless user
      raise InvalidRefreshTokenError, "User not found"
    end

    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def self.get_user_id(raw_token)
    return nil unless raw_token
    token_hash = raw_token_encrypt(raw_token)
    user_id = $redis.get("refresh_token:#{token_hash}")
    return nil unless user_id
    user_id
  end

  def self.raw_token_encrypt(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
