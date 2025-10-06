module CookiesModifier
  include ActiveSupport::Concern

  def cookies_sign(refresh_token, remember_me)
    cookies.signed[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      expires: remember_me ? 30.days.from_now : nil
    }
  end

  def cookies_delete
    cookies.delete(:refresh_token)
  end
end
