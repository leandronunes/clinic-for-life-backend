require "aws-sdk-s3"

# Generates S3 presigned PUT URLs so the frontend can upload videos
# directly to S3 without routing the binary payload through this server.
#
# ENV vars required:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, S3_BUCKET
# Optional:
#   S3_PRESIGN_EXPIRY  — seconds the presigned URL stays valid (default 600)
class S3Presigner
  ALLOWED_CONTEXTS = %w[exercise_video evolution_photo].freeze

  ALLOWED_CONTENT_TYPES = %w[
    video/mp4
    video/webm
    video/quicktime
    video/x-msvideo
    video/mpeg
    video/ogg
    image/jpeg
    image/png
    image/webp
    image/heic
    image/heif
  ].freeze

  EXTENSION_FOR = {
    "video/mp4"       => "mp4",
    "video/webm"      => "webm",
    "video/quicktime" => "mov",
    "video/x-msvideo" => "avi",
    "video/mpeg"      => "mpeg",
    "video/ogg"       => "ogv",
    "image/jpeg"      => "jpg",
    "image/png"       => "png",
    "image/webp"      => "webp",
    "image/heic"      => "heic",
    "image/heif"      => "heif"
  }.freeze

  ConfigurationError = Class.new(StandardError)
  InvalidParamsError = Class.new(ArgumentError)

  def presign(content_type:, context:)
    validate!(content_type:, context:)

    # Use only the base MIME type (strips codecs/params) for extension lookup and presigning
    mime = content_type.to_s.split(";").first.to_s.strip
    ext = EXTENSION_FOR.fetch(mime, "mp4")
    key = "uploads/#{context}/#{SecureRandom.uuid}.#{ext}"

    upload_url = presigner.presigned_url(
      :put_object,
      bucket: bucket,
      key: key,
      expires_in: expiry,
      content_type: mime
    )

    public_url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"

    { upload_url: upload_url, public_url: public_url }
  end

  private

  def validate!(content_type:, context:)
    unless ALLOWED_CONTEXTS.include?(context)
      raise InvalidParamsError, "Context not allowed: #{context}"
    end

    # Strip codec parameters (e.g. "video/webm;codecs=vp9,opus" → "video/webm")
    mime = content_type.to_s.split(";").first.to_s.strip
    unless ALLOWED_CONTENT_TYPES.include?(mime)
      raise InvalidParamsError, "Content type not allowed: #{content_type}"
    end
  end

  def presigner
    @presigner ||= Aws::S3::Presigner.new(client: Aws::S3::Client.new(region: region))
  end

  def bucket
    @bucket ||= ENV.fetch("S3_BUCKET") { raise ConfigurationError, "S3_BUCKET not configured" }
  end

  def region
    @region ||= ENV.fetch("AWS_REGION", "us-east-1")
  end

  def expiry
    ENV.fetch("S3_PRESIGN_EXPIRY", "600").to_i
  end
end
