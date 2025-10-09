require "net/http"
require "uri"
require "json"
require "jwt"

class Api::V1::LineAuthController < ApplicationController
  include ActionController::Cookies
  include CookiesModifier

  def login_with_line
    code = params[:code]
    remember_me = params[:remember_me]
    return render json: { error: "Code is required" }, status: :bad_request unless code

    token_data = exchange_code_for_token(code)
    if token_data["error"]
      return render json: { error: token_data["error_description"] }, status: :unauthorized
    end

    line_profile = get_line_profile(token_data["access_token"])

    user = User.find_by(line_user_id: line_profile["userId"])
    if user.is_locked?
      render json: {
        message: "your account has been locked",
      }, status: :ok 
      return
    end
    user.update_tracked_fields!(request)

    refresh_token = RefreshTokenService.create_for_user(user, remember_me)
    cookies_sign(refresh_token, remember_me)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    response.set_header("authorization", "Bearer #{token}")
    render json: {
      message: "signed in successfully",
      user: { id: user.id, email: user.email, full_name: user.full_name, line_user_id: user.line_user_id }
    }, status: :ok
  end

  def link_with_line_account
    code = params[:code]
    render json: { error: "Code is required" }, status: :bad_request unless code
    render json: { error: "This account has already linked to a Line account" }, status: :bad_request if current_user.line_user_id
    token_data = exchange_code_for_token(params[:code])
    puts token_data
    line_profile = get_line_profile(token_data["access_token"])
    if current_user.update(line_user_id: line_profile["userId"])
      render json: { message: "Account has been successfully linked" }, status: :ok
    else
      render json: { error: "Failed to link account", details: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def exchange_code_for_token(code)
    uri = URI("https://api.line.me/oauth2/v2.1/token")
    res = Net::HTTP.post_form(uri, {
      grant_type: "authorization_code",
      code: code,
      redirect_uri: ENV["LINE_REDIRECT_URI"],
      client_id: ENV["LINE_CHANNEL_ID"],
      client_secret: ENV["LINE_CHANNEL_SECRET"]
    })
    JSON.parse(res.body)
  end

  def get_line_profile(access_token)
    uri = URI("https://api.line.me/v2/profile")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    JSON.parse(res.body)
  end
end
