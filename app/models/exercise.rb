class Exercise < ApplicationRecord
  belongs_to :workout

  validates :name, presence: true
  validates :sets, numericality: { greater_than: 0 }
  validates :rest_seconds, numericality: { greater_than_or_equal_to: 0 }
end
