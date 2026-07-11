require "aws-sdk-s3"

# Generates S3 presigned PUT URLs so the frontend can upload videos
# directly to S3 without routing the binary payload through this server,
# and presigned GET URLs so private objects (exercise videos, evolution
# photos, exams, biomechanical images) can be viewed without making the
# bucket world-readable. Only partner_logo stays on a public bucket policy —
# it's meant to be public (the partner showcase).
#
# ENV vars required:
#   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, S3_BUCKET
# Optional:
#   S3_PRESIGN_EXPIRY      — seconds an upload URL stays valid (default 600)
#   S3_GET_PRESIGN_EXPIRY  — seconds a view URL stays valid (default 900)
class S3Presigner
  ALLOWED_CONTEXTS = %w[exercise_video evolution_photo biomechanical_image exam partner_logo].freeze

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
    application/pdf
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
    "image/heif"      => "heif",
    "application/pdf" => "pdf"
  }.freeze

  ConfigurationError = Class.new(StandardError)
  InvalidParamsError = Class.new(ArgumentError)

  # Rewrites `url` into a short-lived presigned GET URL when it points at
  # our own bucket; anything else (a YouTube embed, a fixture URL in
  # tests, or S3 not being configured) is returned unchanged.
  def self.presign_get_for(url)
    new.presign_get_for(url)
  end

  def presign(content_type:, context:, student_id: nil)
    validate!(content_type:, context:)

    # Use only the base MIME type (strips codecs/params) for extension lookup and presigning
    mime = content_type.to_s.split(";").first.to_s.strip
    ext = EXTENSION_FOR.fetch(mime, "mp4")
    key = "#{env_prefix}uploads/#{key_scope(context, student_id)}/#{SecureRandom.uuid}.#{ext}"

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

  # Deletes an object from S3 identified by its public URL.
  def delete(public_url:)
    key = extract_key(public_url)
    s3_client.delete_object(bucket: bucket, key: key)
  end

  def presign_get_for(url, expires_in: get_expiry)
    return url if url.blank?
    return url unless url.to_s.start_with?("https://#{bucket}.s3.#{region}.amazonaws.com/")

    presigner.presigned_url(:get_object, bucket: bucket, key: extract_key(url), expires_in: expires_in)
  rescue ConfigurationError
    url
  end

  private

  # Uploads tied to a student are namespaced under students/#{id}; uploads with
  # no student (e.g. partner_logo) are namespaced by context alone.
  def key_scope(context, student_id)
    student_id ? "students/#{student_id}/#{context}" : context.to_s
  end

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

  def extract_key(url)
    URI.parse(url).path.delete_prefix("/")
  rescue URI::InvalidURIError
    raise InvalidParamsError, "Invalid URL: #{url}"
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: region)
  end

  def presigner
    @presigner ||= Aws::S3::Presigner.new(client: s3_client)
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

  def get_expiry
    ENV.fetch("S3_GET_PRESIGN_EXPIRY", "900").to_i
  end

  def env_prefix
    Rails.env.development? ? "dev/" : ""
  end
end
