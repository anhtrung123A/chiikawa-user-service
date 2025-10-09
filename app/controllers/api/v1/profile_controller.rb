class Api::V1::ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: {user: current_user.as_json, default_address: current_user.default_address.as_json }, status: :ok
  end

end