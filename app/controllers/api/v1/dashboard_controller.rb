module Api
  module V1
    class DashboardController < BaseController
      before_action -> { require_role!(:admin, :personal) }

      # GET /api/v1/dashboard/kpis
      def kpis
        scope = student_scope
        days  = range_days

        cards = [
          { label: "Active Students", value: scope.where(status: "active").count,
            icon: "users",     delta: delta_pct(scope, days) },
          { label: "Trainers",        value: trainer_scope.count,
            icon: "trainer",   delta: delta_pct(Trainer, days) },
          { label: "Partners",        value: Partner.count,
            icon: "handshake", delta: delta_pct(Partner, days) },
          { label: "Assessments",     value: assessment_count(scope),
            icon: "clipboard", delta: assessment_delta(scope, days) },
          { label: "Active Workouts", value: Workout.active.where(student: scope).count,
            icon: "dumbbell",  delta: delta_pct(Workout.where(student: scope), days) }
        ]

        render_data(cards)
      end

      # GET /api/v1/dashboard/activity
      def activity
        scope      = student_scope
        days       = range_days.clamp(1, 365)
        start_date = days.days.ago.to_date

        workouts = Workout.where(student: scope).where(created_at: start_date..)
                          .group("date(created_at)").count
        measurements = BioimpedanceMeasurement.where(student: scope)
                                              .where(measured_on: start_date..)
                                              .group(:measured_on).count

        series = (start_date..Date.current).map do |day|
          {
            label:       day.iso8601,
            workouts:    workouts[day] || 0,
            assessments: measurements[day] || 0
          }
        end

        render_data(series)
      end

      private

      def range_days
        { "day" => 1, "week" => 7, "year" => 365 }.fetch(params[:range]&.to_s, 30)
      end

      # % change: records created in the current period vs the previous same-length period.
      def delta_pct(relation, days)
        curr_start = days.days.ago
        prev_start = (days * 2).days.ago
        curr = relation.where(created_at: curr_start..).count
        prev = relation.where(created_at: prev_start...curr_start).count
        return 0.0 if prev.zero?

        ((curr - prev) / prev.to_f * 100).round(1)
      end

      def assessment_delta(scope, days)
        curr_date = days.days.ago.to_date
        prev_date = (days * 2).days.ago.to_date
        curr = BiomechanicalAssessment.where(student: scope).where(created_at: curr_date..).count +
               BioimpedanceMeasurement.where(student: scope).where(measured_on: curr_date..).count
        prev = BiomechanicalAssessment.where(student: scope).where(created_at: prev_date...curr_date).count +
               BioimpedanceMeasurement.where(student: scope).where(measured_on: prev_date...curr_date).count
        return 0.0 if prev.zero?

        ((curr - prev) / prev.to_f * 100).round(1)
      end

      def trainer_scope
        return Trainer.where(id: current_user.trainer_id) if current_user.personal?

        Trainer.all
      end

      def student_scope
        return Student.where(trainer_id: current_user.trainer_id) if current_user.personal?

        Student.all
      end

      def assessment_count(scope)
        BiomechanicalAssessment.where(student: scope).count +
          BioimpedanceMeasurement.where(student: scope).count
      end
    end
  end
end
