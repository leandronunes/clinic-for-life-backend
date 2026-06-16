class EvolutionPhoto < ApplicationRecord
  belongs_to :student

  validates :taken_on, presence: true
  validates :image_url, presence: true
end
