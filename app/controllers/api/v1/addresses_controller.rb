class Api::V1::AddressesController < ApplicationController
  before_action :authenticate_user!

  def index
    addresses = current_user.addresses
    render json: { data: addresses.as_json }, status: :ok
  end

  def show
    address = Address.find(params[:id]) || nil
    authorize address
    if address
      render json: { data: address.as_json }, status: :ok
    else
      render json: { message: "address not found" }, status: :ok
    end
  end

  def create
    address = Address.new(address_params)
    address.user = current_user
    if address.save!
      render json: { message: "success" }, status: :created
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    address = Address.find(params[:id]) || nil
    if address.destroy!
      render json: { message: "success" }, status: :ok
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
  end

  private

  def address_params
    params.require(:address).permit(:city, :location_detail, :recipient_name, :phone_number)
  end
end
