# Vincula um treino confirmado pelo personal ao horário da agenda daquele dia
# (independente do horário bater com o planejado) — ou cria um horário avulso
# quando não existe nenhum pra aquele dia. Chamado pelo callback em
# WorkoutCheckIn assim que o check-in fica completed + personal_confirmed_at.
class ScheduleSessionLinkerService
  DEFAULT_DURATION_MINUTES = 60
  LINKABLE_STATUSES = %w[planned missed].freeze

  def self.call(check_in) = new(check_in).call

  def initialize(check_in)
    @check_in = check_in
  end

  def call
    # Consulta direta (não check_in.schedule_session) — evita cache de
    # associação: se o mesmo objeto em memória chamar #call duas vezes (ex.:
    # testes, ou uma race dentro do mesmo request), a leitura via associação
    # ficaria presa no resultado (nil) já cacheado da primeira chamada.
    return if ScheduleSession.exists?(workout_check_in_id: check_in.id)

    trainer = check_in.student.trainer
    return if trainer.nil?

    if (session = existing_session_for_day)
      session.update!(status: "done", workout_check_in_id: check_in.id, workout_id: check_in.workout_id)
    else
      ScheduleSession.create!(
        student: check_in.student,
        trainer: trainer,
        starts_at: check_in.created_at,
        duration_minutes: DEFAULT_DURATION_MINUTES,
        status: "done",
        workout_id: check_in.workout_id,
        workout_check_in_id: check_in.id
      )
    end
  end

  private

  attr_reader :check_in

  # Considera sessões "planned" ou "missed" — um treino confirmado depois do
  # horário planejado já ter passado encontra a sessão já marcada "missed"
  # pelo ScheduleMissedMarkerService, mas ainda é "o mesmo compromisso".
  # "done" (já vinculada a outro check-in) e "canceled" ficam de fora.
  def existing_session_for_day
    check_in.student.schedule_sessions
             .where(status: LINKABLE_STATUSES, workout_check_in_id: nil)
             .where(starts_at: check_in.created_at.all_day)
             .min_by { |s| (s.starts_at - check_in.created_at).abs }
  end
end
