class Api::PropertiesController < ApplicationController
  before_action :find_property, only: [:update, :destroy, :destroyImage, :addImage]
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
      if params[:property][:images]
        begin
          params[:property][:images].each do |img|
            @property.images.attach(img)
          end
          @property.save!
        rescue => exception
          @property.destroy
          render json: @property.errors.full_messages, status: 401 and return
        end
      end

      render :show
    else
      render json: @property.errors.full_messages, status: 401
    end
  end

  def update
    if @property.update_attributes(property_params)
      if params[:property][:images]
        begin
          params[:property][:images].each do |img|
            @property.images.attach(img)
          end
          @property.save!
        rescue => exception
          puts exception
        end
      end

      render :show
    else
      render json: @property.errors.full_messages, status: 401
    end
  end

  def addImage
    params[:property][:images].each do |img|
      @property.images.attach(img)
    end

    ## send back image urls for updated images only
    @toRender = @property
      .images[(0-params[:property][:images].length)..-1]
      .map { |img| @property.image_url(img) }

    render json: { propId: @property.id, images: @toRender }
  end

  def destroyImage
    ## make sure to return the id of the destroyed image
    ## so the frontend can delete it from redux
    ## this param structure may not be permitted per property_params...
    @blob = ActiveStorage::Blob.find_signed(params[:imageId])
    @image = @property.images.find_by(blob_id: @blob.id)

    @image.purge_later if @image.persisted?
    render json: { deletedImageId: params[:imageId] }
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
    params
      .require(:property)
      .permit(
        :title, 
        :baths, 
        :beds, 
        :description, 
        :nightly_rate, 
        :pets, 
        :smoking, 
        :square_feet, 
        :manager_id, 
        images: [{}]
      )
  end
  
end
