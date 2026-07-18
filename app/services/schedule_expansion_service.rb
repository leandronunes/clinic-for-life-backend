# Expande um SchedulePlan em ocorrências concretas de ScheduleSession, e
# resolve o range de um dia (usado pelo filtro from/to do índice). Espelha
# 1:1 src/lib/schedule.ts::expandPlan do frontend.
#
# TIME_ZONE é hardcoded em America/Sao_Paulo (não Time.zone, que é UTC nesta
# app — não há timezone por trainer/usuário no sistema, e toda a base de
# usuários é do Brasil). Isso replica o horário local que o frontend já
# gera hoje a partir do relógio do browser. O instante resultante é
# convertido para UTC ao persistir — o offset textual no JSON pode sair
# diferente do que o frontend geraria sozinho, mas o instante (o que
# `new Date(iso)` resolve) é idêntico.
class ScheduleExpansionService
  TIME_ZONE = ActiveSupport::TimeZone["America/Sao_Paulo"]

  # Range [início do dia, fim do dia] em America/Sao_Paulo para uma data
  # "YYYY-MM-DD" — usado pelo filtro from/to de ScheduleSessionsController#index.
  def self.day_range(date_string)
    date = Date.parse(date_string.to_s)
    start = TIME_ZONE.local(date.year, date.month, date.day, 0, 0, 0)
    start..start.end_of_day
  end

  # slots: qualquer coleção de objetos com #weekday, #time ("HH:mm") e
  # #duration_minutes (ex.: SchedulePlanSlot). Itera dia a dia de starts_on
  # a ends_on (inclusive); para cada dia cujo weekday bate com algum slot,
  # gera uma ocorrência. Retorna [] se o range for inválido (ends_on antes
  # de starts_on).
  def self.occurrences(slots:, starts_on:, ends_on:)
    start_date = Date.parse(starts_on.to_s)
    end_date = Date.parse(ends_on.to_s)
    return [] if end_date < start_date

    result = []
    cursor = start_date
    while cursor <= end_date
      slots.each do |slot|
        next unless cursor.wday == slot.weekday.to_i

        hour, minute = slot.time.split(":").map(&:to_i)
        starts_at = TIME_ZONE.local(cursor.year, cursor.month, cursor.day, hour, minute, 0)
        result << { starts_at: starts_at, duration_minutes: slot.duration_minutes, weekday: slot.weekday }
      end
      cursor += 1
    end
    result
  end
end
