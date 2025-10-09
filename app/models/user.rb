class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :validatable, :confirmable,
         :jwt_authenticatable, :trackable,
         jwt_revocation_strategy: self
  has_many :addresses
  enum :role, {
    customer: "customer",
    admin: "admin"
  }
  validates :email, :full_name, presence: true
  before_create :set_jti
  include Devise::JWT::RevocationStrategies::JTIMatcher

  def jwt_payload
    {
      "sub" => id,
      "jti" => jti,
      "email" => email,
      "full_name" => full_name,
      "role" => role
    }
  end

  def send_devise_notification(notification, *args)
    # For confirmable, we’ll handle manually
    if notification == :confirmation_instructions
      SendConfirmationEmailJob.perform_later(id)
    else
      super
    end
  end

  def is_locked?
    locked_at != nil
  end

  def default_address
    addresses.where(is_default_address: true).first || nil
  end

  def self.lock_inactive_account
    puts "locked accounts which are inactive for more than 60 days"
    threshold = 60.days.ago
    where("last_sign_in_at >= ? AND locked_at IS NULL", threshold).update_all(locked_at: Time.current)
  end

  private

  def set_jti
    self.jti = SecureRandom.uuid if jti.blank?
  end
end
