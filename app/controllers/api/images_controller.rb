class Api::ImagesController < ApplicationController
  def exchangeImageIdForS3Url
    @imageBlob = ActiveStorage::Blob.find_signed(params[:blobId])
    @s3Url = @imageBlob.url

    render json: { url: @s3Url }
  end
end
