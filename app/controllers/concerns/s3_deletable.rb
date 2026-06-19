module S3Deletable
  extend ActiveSupport::Concern

  private

  def delete_from_s3(url)
    return if url.blank?
    return unless url.include?(".amazonaws.com/")

    S3Presigner.new.delete(public_url: url)
  rescue StandardError => e
    Rails.logger.warn("Could not delete S3 object #{url}: #{e.message}")
  end
end
