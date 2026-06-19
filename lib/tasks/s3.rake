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
        allowed_headers: ["Content-Type"],
        allowed_methods: ["PUT"],
        allowed_origins: origins,
        expose_headers:  ["ETag"],
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
