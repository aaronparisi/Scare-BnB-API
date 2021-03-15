class Api::RatingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def addManagerRating
    @rating = ManagerRating.new(rating_params)

    if @rating.save
      @user = User.find(@rating.manager_id)
      render partial: 'api/users/user', locals: { user: @user, manager_rating: @user.manager_rating }
    else
      render json: @rating.errors.full_messages, status: 401
    end
  end

  def addGuestRating
    @rating = GuestRating.new(rating_params)

    if @rating.save
      @user = User.find(@rating.guest_id)
      render partial: 'api/users/user', locals: { user: @user, guest_rating: @user.guest_rating }
    else
      render json: @rating.errors.full_messages, status: 401
    end
  end

  private

  def rating_params
    params.require(:rating).permit(:manager_id, :guest_id, :rating)
  end
  
end
