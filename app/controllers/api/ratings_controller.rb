class Api::RatingsController < ApplicationController
  skip_before_action :verify_authenticity_token  

  def updateManagerRating
    @rating = ManagerRating.find_by(
      guest_id: params[:rating][:guest_id], 
      manager_id: params[:rating][:manager_id]
    )
  
    if @rating.update(rating: params[:rating][:rating])
      @user = User.find(@rating.manager_id)
      # render partial: 'api/users/user', locals: { user: @user, manager_rating: @user.manager_rating }
      render partial: 'api/users/user_plus_rating', 
        locals: { user: @user, manager_rating: @user.manager_rating, made_ratings: [@rating]}
    else
      render json: @rating.errors.full_messages, status: 401
    end
  end
  

  def addManagerRating
    @rating = ManagerRating.new(rating_params)

    if @rating.save
      @user = User.find(@rating.manager_id)
      render partial: 'api/users/user_plus_rating', 
        locals: { user: @user, manager_rating: @user.manager_rating, made_ratings: [@rating]}
    else
      render json: @rating.errors.full_messages, status: 401
    end
  end

  def updateGuestRating
    
  end
  

  def addGuestRating
    @rating = GuestRating.find_by(manager_id: params[rating][manager_id]) || 
    GuestRating.new(rating_params)

    if @rating.save
      @user = User.find(@rating.guest_id)
      render partial: 'api/users/user_plus_rating', 
        locals: { user: @user, guest_rating: @user.guest_rating, made_rating: @rating }
    else
      render json: @rating.errors.full_messages, status: 401
    end
  end

  private

  def rating_params
    params.require(:rating).permit(:manager_id, :guest_id, :rating)
  end
  
end
