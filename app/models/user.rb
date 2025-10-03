class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self
  has_many :addresses
  enum :role, {
    customer: 'customer',
    admin: 'admin'
  }
  validates :email, :full_name, presence: true
  before_create :set_jti
  include Devise::JWT::RevocationStrategies::JTIMatcher

  def jwt_payload
    {
      'sub' => id,
      'jti' => jti,
      'email' => email,
      'full_name' => full_name,
      "role" => role
    }
  end

  private

  def set_jti
    self.jti = SecureRandom.uuid if jti.blank?
  end
end
