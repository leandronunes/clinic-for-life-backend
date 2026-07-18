# student_name/trainer_name são resolvidos aqui a partir das associações
# (nunca persistidos) — o controller precisa de .includes(:student, :trainer)
# para não gerar N+1 numa lista de calendário.
class ScheduleSessionSerializer
  def initialize(session)
    @session = session
  end

  def as_json(*)
    {
      id: @session.id.to_s,
      student_id: @session.student_id.to_s,
      student_name: @session.student.name,
      trainer_id: @session.trainer_id.to_s,
      trainer_name: @session.trainer&.name,
      starts_at: @session.starts_at.iso8601,
      duration_minutes: @session.duration_minutes,
      status: @session.status,
      workout_id: @session.workout_id&.to_s,
      notes: @session.notes,
      plan_id: @session.schedule_plan_id&.to_s
    }
  end
end
