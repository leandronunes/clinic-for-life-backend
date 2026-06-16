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

  before_save :compute_bmi

  private

  def measured_on_not_in_future
    return if measured_on.blank?

    errors.add(:measured_on, "cannot be in the future") if measured_on > Date.current
  end

  # Derive BMI from weight and the student's height when not provided.
  def compute_bmi
    return if bmi.present?
    return if weight_kg.blank? || student&.height_cm.to_i <= 0

    height_m = student.height_cm / 100.0
    self.bmi = (weight_kg.to_f / (height_m * height_m)).round(2)
  end
end
