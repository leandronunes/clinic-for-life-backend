class EvolutionPhoto < ApplicationRecord
  belongs_to :student
  belongs_to :bioimpedance_measurement, optional: true

  validates :taken_on, presence: true
  validates :image_url, presence: true
  validates :bioimpedance_measurement_id, uniqueness: true, allow_nil: true
end
