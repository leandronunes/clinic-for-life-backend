module Api
  module V1
    class WorkoutReactionsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: :create
      before_action :set_workout

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:check_in_id/reaction
      # Upsert: reacting again replaces the current user's existing reaction
      # on this check-in instead of accumulating duplicates.
      def create
        check_in = @workout.workout_check_ins.find(params[:check_in_id])
        return render_not_completed unless check_in.status == "completed"

        reaction = check_in.workout_reactions.find_or_initialize_by(author: current_user)
        reaction.update!(emoji: params[:emoji])
        audit!("workout_reaction.create", record: reaction)
        notify_student_of_reaction(check_in, reaction)
        render_data(WorkoutReactionSerializer.new(reaction).as_json, status: :created)
      end

      private

      def set_workout
        @workout = @student.workouts.find(params[:workout_id])
      end

      def render_not_completed
        render json: { error: "Só é possível reagir a um treino concluído" },
               status: :unprocessable_content
      end

      # Best-effort push ao aluno — mesmo padrão de
      # FeedbacksController#notify_student_of_feedback.
      def notify_student_of_reaction(check_in, reaction)
        student_user = @student.user
        return if student_user.blank?

        PushNotificationJob.perform_later(
          student_user.id,
          title: "Seu personal reagiu ao seu treino!",
          body: "#{reaction.emoji} no treino \"#{check_in.workout.title}\".",
          url: "/aluno/assiduidade"
        )
      end
    end
  end
end
