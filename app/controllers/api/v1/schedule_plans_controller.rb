module Api
  module V1
    class SchedulePlansController < BaseController
      before_action -> { require_role!(:admin, :personal) }

      # POST /api/v1/schedule_plans
      #
      # Cria o plano recorrente e expande em N ScheduleSession de uma vez
      # (insert_all!, não um loop de create! — CLAUDE.md exige operações em
      # lote; o volume aqui pode passar de mil linhas). Seguro porque cada
      # linha já vem de um SchedulePlanSlot validado antes do insert.
      def create
        student = Student.find(params[:student_id])
        authorize_staff_for_student!(student)
        return if performed?

        plan = student.schedule_plans.new(plan_params.merge(trainer_id: student.trainer_id))
        weekday_params.each { |w| plan.schedule_plan_slots.build(w) }

        sessions = nil
        ActiveRecord::Base.transaction do
          plan.save!

          occurrences = ScheduleExpansionService.occurrences(
            slots: plan.schedule_plan_slots, starts_on: plan.starts_on, ends_on: plan.ends_on
          )
          now = Time.current
          rows = occurrences.map do |occ|
            {
              student_id: student.id,
              trainer_id: student.trainer_id,
              schedule_plan_id: plan.id,
              starts_at: occ[:starts_at],
              duration_minutes: occ[:duration_minutes],
              status: "planned",
              notes: plan.notes,
              created_at: now,
              updated_at: now
            }
          end
          ScheduleSession.insert_all!(rows) if rows.any?
          sessions = ScheduleSession.where(schedule_plan_id: plan.id)
                                     .includes(:student, :trainer)
                                     .order(:starts_at)
        end

        audit!("schedule_plan.create", record: plan)
        render_data(
          { created: sessions.size, sessions: sessions.map { |s| ScheduleSessionSerializer.new(s).as_json } },
          status: :created
        )
      end

      private

      def plan_params
        params.permit(:starts_on, :ends_on, :notes)
      end

      def weekday_params
        (params[:weekdays] || []).map { |w| w.permit(:weekday, :time, :duration_minutes).to_h.symbolize_keys }
      end
    end
  end
end
