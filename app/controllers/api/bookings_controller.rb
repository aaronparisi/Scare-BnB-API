class Api::BookingsController < ApplicationController
  before_action :find_booking, only: [:show, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :update]

  def index
    @bookings = Booking.where(guest_id: params[:id]).includes(:property, :guest)
    # ? include other info?
  end

  def managedIndex
    @bookings = Booking.where(manager_id: params[:id]).includes(:property, :guest)
  end

  def show
    
  end

  def create
    @booking = Booking.new(booking_params)
    if @booking.save
      render :show
    else
      render json: @booking.errors.full_messages, status: 401
    end
  end

  def upate
    if @booking.update_attributes(booking_params)
      render :show
    else
      render json: @booking.errors.full_messages, status: 401
    end
  end

  def destroy
    if @booking.destroy
      render :show
    else
      render ['Error destroying booking']
    end
  end

  private

  def find_booking
     @booking = Booking.includes(:property, :guest).find(params[:id])
  end
  
  def booking_params
    params.require(:booking).permit(:start_date, :end_date, :guest_id, :property_id)
  end
end
