

require 'aws-sdk-s3'
require 'json'
# require 'jwt'

def handler(event:, context:)
  puts event
  # return cors headers for preflight check
  if event['routeKey'] == "OPTIONS /{proxy+}"
    puts({step: 'preflight', message: 'preflight CORS check'}.to_json)
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
      # "Access-Control-Allow-Origin": "https://3000-abdassalama-awsbootcamp-6ws4ndklsng.ws-eu96b.gitpod.io",
      "Access-Control-Allow-Origin": "*",# maybe I can use this for production.
        "Access-Control-Allow-Methods": "OPTIONS"
      },
      statusCode: 200
    }
  else
    puts("event", event)
    token = event['headers']['authorization']
    puts({step: 'presignedurl', access_token: token}.to_json)

    body_hash = JSON.parse(event["body"])
    extension = body_hash["extension"]
    
    # for banner
    banner_or_avatar = body_hash["banner_or_avatar"]
    puts(banner_or_avatar)
    
    # decoded_token = JWT.decode token, nil, false
    # cognito_user_uuid = decoded_token[0]['sub']
    cognito_user_uuid = event["requestContext"]["authorizer"]["lambda"]["sub"]

    puts({step:'presign url', sub_value: cognito_user_uuid}.to_json)

    s3 = Aws::S3::Resource.new
    bucket_name = ENV["UPLOADS_BUCKET_NAME"]

    
    # for banner
    # if banner_or_avatar == "banner"
    #   object_key = "#{banner_or_avatar}-#{cognito_user_uuid}.#{extension}"
    # else
    #   object_key = "#{cognito_user_uuid}.#{extension}"
    
    if banner_or_avatar == "banner" || banner_or_avatar == "avatar"
      if banner_or_avatar == "banner"
        object_key = "#{banner_or_avatar}-#{cognito_user_uuid}.#{extension}"
      else
        object_key = "#{cognito_user_uuid}.#{extension}"
      end
    else
      puts "Invalid value for banner_or_avatar: #{banner_or_avatar}"
    end

    puts({object_key: object_key}.to_json)

    obj = s3.bucket(bucket_name).object(object_key)
    url = obj.presigned_url(:put, expires_in: 60 * 5)
    url # this is the data that will be returned
    
    body = {url: url}.to_json
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
      # "Access-Control-Allow-Origin": "https://3000-abdassalama-awsbootcamp-6ws4ndklsng.ws-eu96b.gitpod.io",
      "Access-Control-Allow-Origin": "*",# maybe I can use this for production.
        "Access-Control-Allow-Methods": "POST"
      },
      statusCode: 200, 
      body: body 
    }
  end # if 
end # def handler