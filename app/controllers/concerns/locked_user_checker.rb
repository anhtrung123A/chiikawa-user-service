module LockedUserChecker
  include ActiveSupport::Concern

  def is_user_locked(user)
    if user.is_locked?
      render json: {
        message: "your account has been locked",
      }, status: :forbidden 
      return true
    end
    false
  end
end
