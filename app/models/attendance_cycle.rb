class AttendanceCycle < ApplicationRecord
  belongs_to :student

  validates :contracted_workouts_per_cycle,
            presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validate :ended_at_after_started_at

  # Treinos concluídos dentro dos limites deste ciclo já encerrado. Só conta
  # check-ins com performed_by "personal" — um check-in feito pelo próprio
  # aluno não consome a quota contratada até o personal confirmá-lo (ver
  # WorkoutCheckInsController#claim).
  def completed_workouts
    student.workout_check_ins.completed.performed_by_personal
           .where(completed_at: started_at..ended_at).count
  end

  private

  def ended_at_after_started_at
    return if started_at.blank? || ended_at.blank? || ended_at > started_at

    errors.add(:ended_at, "must be after started_at")
  end
end
