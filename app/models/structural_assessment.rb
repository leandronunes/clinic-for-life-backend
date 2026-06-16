class StructuralAssessment < ApplicationRecord
  belongs_to :student

  # Boolean structural findings exposed by the assessment screen.
  ITEMS = %w[
    scoliosis
    spine_rotation
    hip_rotation
    scapular_girdle_imbalance
    scapular_dyskinesis
    shortening
    limb_length_difference
    pelvic_anteversion
    pelvic_retroversion
    knee_valgus
    knee_varus
    cavus_foot_arch
    flat_foot_arch
  ].freeze
end
