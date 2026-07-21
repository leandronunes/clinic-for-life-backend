class WorkoutCheckIn < ApplicationRecord
  STATUSES = %w[in_progress completed].freeze

  belongs_to :workout
  belongs_to :student
  has_many :exercise_check_ins, dependent: :destroy
  has_many :check_in_feedbacks, dependent: :destroy
  has_one :schedule_session, dependent: :nullify

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :pse, inclusion: { in: 1..10 }, allow_nil: true

  after_save :link_to_schedule_session, if: :ready_for_schedule_link?

  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }
  # Drives attendance-cycle counting (see AttendanceCycle#completed_workouts):
  # a check-in only counts against the trainer's contracted quota once BOTH
  # the student and staff (personal/admin) have confirmed it — whoever
  # actually performs the check-in flow (create/toggle/finish) has their own
  # side auto-confirmed (see WorkoutCheckInsController#create); the other
  # side confirms explicitly via #confirm.
  scope :mutually_confirmed, -> { where.not(student_confirmed_at: nil).where.not(personal_confirmed_at: nil) }

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

  def mutually_confirmed?
    student_confirmed_at.present? && personal_confirmed_at.present?
  end

  def confirm_as_student!
    update!(student_confirmed_at: Time.current) if student_confirmed_at.nil?
  end

  def confirm_as_personal!
    update!(personal_confirmed_at: Time.current) if personal_confirmed_at.nil?
  end

  private

  # "Confirmado pelo personal" (independente de quem performou o check-in)
  # é o gatilho pra vincular esse treino à agenda — ver
  # ScheduleSessionLinkerService. Guardado por saved_change_to_*? pra não
  # disparar em saves não relacionados (ex.: update_pse, mark_viewed!).
  def ready_for_schedule_link?
    (saved_change_to_status? || saved_change_to_personal_confirmed_at?) &&
      status == "completed" && personal_confirmed_at.present?
  end

  def link_to_schedule_session
    ScheduleSessionLinkerService.call(self)
  end
end
