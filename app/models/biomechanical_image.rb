class BiomechanicalImage < ApplicationRecord
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
end
