# Marca como "missed" toda ScheduleSession "planned" cujo horário de término
# (starts_at + duration_minutes) já passou. Uma única query em lote
# (update_all) — sem loop, sem callbacks/validações (não há nada para
# validar: só muda o status de linhas já existentes e válidas). Reaproveitado
# pelo endpoint interno de cron (Api::V1::CronController) e pela rake task
# (lib/tasks/schedule.rake).
class ScheduleMissedMarkerService
  def self.call
    ScheduleSession.where(status: "planned")
                   .where("starts_at + (duration_minutes * interval '1 minute') < ?", Time.current)
                   .update_all(status: "missed", updated_at: Time.current)
  end
end
