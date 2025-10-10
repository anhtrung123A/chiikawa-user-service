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
      render json: { error: "address not found" }, status: :not_found
    end
  end

  def create
    address = Address.new(address_params)
    address.is_default_address = true if current_user.addresses.count == 0
    address.user = current_user
    if address.save!
      render json: { message: "success" }, status: :created
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    address = Address.find(params[:id]) || nil
    authorize address
    if (address.is_default_address)
      render json: { error: "You can't delete default address." }, status: :bad_request
      return
    end
    if address.destroy!
      render json: { message: "success" }, status: :ok
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    address = Address.find(params[:id]) || nil
    authorize address
    current_user.addresses.update_all(is_default_address: false)
    if address.update(address_params)
      render json: { message: "success", data: address.as_json }, status: :ok
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def set_default_address
    address = Address.find(params[:id]) || nil
    authorize address
    current_user.addresses.update_all(is_default_address: false)
    if address.update(is_default_address: true)
      render json: { message: "success" }, status: :ok
    else
      render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show_default_address
    address = current_user.default_address
    if address
      render json: { data: address.as_json }, status: :ok
    else
      render json: { message: "You haven't created any addresses yet." }, status: :ok
    end
  end

  private

  def address_params
    params.require(:address).permit(:city, :location_detail, :recipient_name, :phone_number, :country, :province, :is_default_address)
  end
end
