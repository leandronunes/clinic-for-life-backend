class Partner < ApplicationRecord
  CATEGORIES = [
    "Nutrition",
    "Physiotherapy",
    "Sports Medicine",
    "Supplementation",
    "Aesthetics",
    "Laboratories"
  ].freeze

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
