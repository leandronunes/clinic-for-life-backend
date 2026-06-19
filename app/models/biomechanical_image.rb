class BiomechanicalImage < ApplicationRecord
  include S3Deletable

  SLOTS = %w[
    frontal
    posterior
    trunk_flexion
    left_side
    right_side
    profile_flexion
  ].freeze

  belongs_to :biomechanical_assessment

  validates :slot, presence: true, inclusion: { in: SLOTS },
                   uniqueness: { scope: :biomechanical_assessment_id }
  validates :image_url, presence: true

  before_destroy { delete_from_s3(image_url) }
end
