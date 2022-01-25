class Api::ImagesController < ApplicationController
  def exchangeImageIdForS3Url
    @urls = params[:blob_ids].map do |blob_id|
      image = ActiveStorage::Blob.find_signed(blob_id)
      url = image.url

      { url: url, id: blob_id }
    end

    render json: @urls
    ## remove jbuilder views for this?  seems excessive...
  end

  ## strong params needed?
end
