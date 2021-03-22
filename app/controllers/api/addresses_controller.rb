class Api::AddressesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @address = Address.new(address_params)
    
    if @address.save
      # ? I don't think the return value really matters?
      render :show
    else
      render json: @address.errors.full_messages, status: 401
    end
  end
  
  private

  def address_params
    params.require(:address).permit(:line_1, :line_2, :city, :state, :zip, :property_id)
  end
  
end
