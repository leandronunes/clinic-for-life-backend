class WorkoutCheckIn < ApplicationRecord
  STATUSES = %w[in_progress completed].freeze

  belongs_to :workout
  belongs_to :student
  has_many :exercise_check_ins, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }

  def exercises_total
    workout.exercises.count
  end

  def exercises_completed_count
    exercise_check_ins.count
  end

  def finish!
    update!(status: "completed", completed_at: Time.current)
  end

  def maybe_auto_finish!
    return unless status == "in_progress"

    finish! if exercises_total.positive? && exercises_completed_count >= exercises_total
  end
end
