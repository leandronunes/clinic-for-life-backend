class Exercise < ApplicationRecord
  KINDS = %w[strength cardio mobility].freeze
  DISTANCE_UNITS = %w[m km].freeze
  HR_ZONES = (1..5).to_a.freeze

  belongs_to :workout
  has_many :exercise_check_ins, dependent: :destroy

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :sets, numericality: { greater_than: 0 }
  validates :rest_seconds, numericality: { greater_than_or_equal_to: 0 }
  validates :reps, presence: true, if: -> { kind.in?(%w[strength mobility]) }
  validates :muscle_group, presence: true, if: -> { kind == "strength" }
  validates :distance_unit, inclusion: { in: DISTANCE_UNITS }, allow_nil: true
  validates :hr_zone, inclusion: { in: HR_ZONES }, allow_nil: true
  validate :cardio_requires_duration_or_distance, if: -> { kind == "cardio" }

  private

  def cardio_requires_duration_or_distance
    return if duration_seconds.to_i.positive? || distance_value.to_f.positive?

    errors.add(:base, "cardio precisa de tempo ou distância")
  end
end
