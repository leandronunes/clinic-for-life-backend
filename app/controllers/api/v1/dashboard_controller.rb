module Api
  module V1
    class DashboardController < BaseController
      before_action -> { require_role!(:admin, :personal) }

      # GET /api/v1/dashboard/kpis
      def kpis
        scope = student_scope

        cards = [
          { label: "Active Students", value: scope.where(status: "active").count, icon: "users" },
          { label: "Trainers", value: trainer_scope.count, icon: "trainer" },
          { label: "Partners", value: Partner.count, icon: "handshake" },
          { label: "Assessments", value: assessment_count(scope), icon: "clipboard" },
          { label: "Active Workouts", value: Workout.active.where(student: scope).count, icon: "dumbbell" }
        ]

        render_data(cards)
      end

      # GET /api/v1/dashboard/activity
      def activity
        scope = student_scope
        days = (params[:days] || 30).to_i.clamp(1, 365)
        start_date = days.days.ago.to_date

        workouts = Workout.where(student: scope).where(created_at: start_date..)
                          .group("date(created_at)").count
        measurements = BioimpedanceMeasurement.where(student: scope)
                                              .where(measured_on: start_date..)
                                              .group(:measured_on).count

        series = (start_date..Date.current).map do |day|
          {
            label: day.iso8601,
            workouts: workouts[day] || 0,
            assessments: measurements[day] || 0
          }
        end

        render_data(series)
      end

      private

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
