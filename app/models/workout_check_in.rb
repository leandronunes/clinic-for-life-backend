class WorkoutCheckIn < ApplicationRecord
  STATUSES = %w[in_progress completed].freeze
  # Who performed the check-in — drives attendance-cycle counting (see
  # AttendanceCycle#completed_workouts): only "personal" (staff-witnessed)
  # check-ins count against the trainer's contracted quota. "aluno" means
  # self check-in, which stays out of that count until/unless staff claims
  # it (WorkoutCheckInsController#claim).
  PERFORMED_BY_VALUES = %w[aluno personal].freeze

  belongs_to :workout
  belongs_to :student
  has_many :exercise_check_ins, dependent: :destroy
  has_many :check_in_feedbacks, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :performed_by, presence: true, inclusion: { in: PERFORMED_BY_VALUES }
  validates :pse, inclusion: { in: 1..10 }, allow_nil: true

  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  scope :performed_by_personal, -> { where(performed_by: "personal") }

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

  def mark_viewed!
    update!(viewed_at: Time.current) unless viewed_at
  end
end
