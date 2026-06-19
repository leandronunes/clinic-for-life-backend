class EvolutionPhoto < ApplicationRecord
  include S3Deletable

  belongs_to :student
  belongs_to :bioimpedance_measurement, optional: true

  validates :taken_on, presence: true
  validates :image_url, presence: true
  validates :bioimpedance_measurement_id, uniqueness: true, allow_nil: true

  before_destroy { delete_from_s3(image_url) }
end
