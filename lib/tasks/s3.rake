require "aws-sdk-s3"

namespace :s3 do
  desc "Apply CORS configuration to the S3 bucket so browsers can PUT presigned uploads directly"
  task configure_cors: :environment do
    bucket  = ENV.fetch("S3_BUCKET")
    region  = ENV.fetch("AWS_REGION", "us-east-1")
    origins = ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip)

    client = Aws::S3::Client.new(region: region)

    cors_rules = [
      {
        allowed_headers: [ "Content-Type" ],
        allowed_methods: [ "PUT" ],
        allowed_origins: origins,
        expose_headers:  [ "ETag" ],
        max_age_seconds: 3000
      }
    ]

    client.put_bucket_cors(
      bucket: bucket,
      cors_configuration: { cors_rules: cors_rules }
    )

    puts "CORS configurado no bucket '#{bucket}':"
    origins.each { |o| puts "  #{o}" }
  end

  desc "Allow public GET on uploads/* so video playback works in the browser"
  task configure_public_read: :environment do
    bucket = ENV.fetch("S3_BUCKET")
    region = ENV.fetch("AWS_REGION", "us-east-1")
    client = Aws::S3::Client.new(region: region)

    # Step 1: lift the Block Public Access settings that would block the bucket policy.
    # We only relax the policy-related controls; ACL-based blocks are left in place.
    client.put_public_access_block(
      bucket: bucket,
      public_access_block_configuration: {
        block_public_acls:       true,  # ACL-based public access still blocked
        ignore_public_acls:      true,
        block_public_policy:     false, # allow the bucket policy below
        restrict_public_buckets: false
      }
    )
    puts "Block Public Access: política pública habilitada."

    # Step 2: apply a bucket policy that allows anonymous GET only on uploads/*
    policy = {
      Version: "2012-10-17",
      Statement: [
        {
          Sid:       "PublicReadForVideoUploads",
          Effect:    "Allow",
          Principal: "*",
          Action:    "s3:GetObject",
          Resource:  "arn:aws:s3:::#{bucket}/uploads/*"
        }
      ]
    }.to_json

    client.put_bucket_policy(bucket: bucket, policy: policy)
    puts "Bucket policy aplicada: GET público em 's3://#{bucket}/uploads/*'."
  end

  desc "Show current CORS configuration of the S3 bucket"
  task show_cors: :environment do
    bucket = ENV.fetch("S3_BUCKET")
    region = ENV.fetch("AWS_REGION", "us-east-1")

    client = Aws::S3::Client.new(region: region)
    resp   = client.get_bucket_cors(bucket: bucket)
    puts JSON.pretty_generate(resp.cors_rules.map(&:to_h))
  rescue Aws::S3::Errors::NoSuchCORSConfiguration
    puts "Nenhuma configuração de CORS encontrada no bucket '#{bucket}'."
  end
end
