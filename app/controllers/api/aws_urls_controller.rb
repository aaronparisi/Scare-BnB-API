class Api::AwsUrlsController < ApplicationController
  def generatePresignedUrl(awsMethod, filename)
    ## given a method as a string (e.g. 'get')
    ##       and a filename as a string,
    ## returns a presigned url from aws

    ## make a new aws client
    ## pulls from storage.yml creds
    aws_client = Aws::S3::Client.new(
      region: aws:region,
      access_key_id: aws:access_key_id,
      secret_access_key: aws:secret_access_key
    )

    ## generate the presigned url
    s3 = Aws::S3::Resource.new(client: aws_client)
    bucket = s3.bucket(aws:bucket)
    obj = bucket.object("${filename}")

    url = obj.presigned_url(awsMethod.to_sym)

    return url
  end
end
