class Address < ApplicationRecord
  belongs_to :user
  validates :phone_number, :city, :location_detail, :recipient_name, :country, :province, presence: true
end
