class BioimpedanceMeasurement < ApplicationRecord
  belongs_to :student

  validates :weight_kg, presence: true,
                        numericality: { greater_than: 0 }
  validates :fat_percentage,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 75 },
            allow_nil: true
  validates :measured_on, presence: true
  validates :measured_on, uniqueness: { scope: :student_id }
  validate :measured_on_not_in_future

  private

  def measured_on_not_in_future
    return if measured_on.blank?

    errors.add(:measured_on, "cannot be in the future") if measured_on > Date.current
  end
end
