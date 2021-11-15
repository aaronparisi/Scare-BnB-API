class Api::PropertiesController < ApplicationController
  before_action :find_property, only: [:update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]

  def index
    if params[:id]
      @properties = Property.where(manager_id: params[:id]).includes(:address, :manager)
    else
      @properties = Property.all.includes(:address, :manager)
    end
    render :index
    # todo - search criteria (eg. distance, price range, beds)
  end
 
  def show
    @property = Property.includes(:address, :manager).find(params[:id])
    render :show
  end
  
  def create
    @property = Property.new(property_params)
    if @property.save
      render :show
    else
      render json: @property.errors.full_messages, status: 401
    end
  end

  def update
    if @property.update_attributes(property_params)
      render :show
    else
      render json: @property.errors.full_messages, status: 401
    end
  end

  def destroy
    if @property.destroy
      render :show
    else
      render ['Error destroying property']
    end
  end

  def find_property
    @property = Property.find(params[:id])
  end
  
  def property_params
    params.require(:property).permit(:title, :baths, :beds, :description, :nightly_rate, :pets, :smoking, :square_feet, :manager_id, :image_directory)
  end
  
end
