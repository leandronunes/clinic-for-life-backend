class Exam < ApplicationRecord
  include S3Deletable

  belongs_to :student

  validates :name, presence: true
  validates :file_url, presence: true

  before_validation { self.uploaded_at ||= Time.current }
  before_destroy { delete_from_s3(file_url) }
end
