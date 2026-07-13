module Api
  module V1
    class FeedbacksController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: :create

      # GET /api/v1/students/:student_id/feedbacks
      def index
        feedbacks = @student.feedbacks.order(created_at: :desc)
        render_data(feedbacks.map { |f| FeedbackSerializer.new(f).as_json })
      end

      # POST /api/v1/students/:student_id/feedbacks
      def create
        check_in = @student.workout_check_ins.find(params[:workout_check_in_id])
        return render_not_completed unless check_in.status == "completed"

        feedback = @student.feedbacks.create!(feedback_params.merge(author: current_user, workout_check_in: check_in))
        audit!("feedback.create", record: feedback)
        notify_student_of_feedback(feedback)
        render_data(FeedbackSerializer.new(feedback).as_json, status: :created)
      end

      private

      def feedback_params
        params.permit(:message)
      end

      def render_not_completed
        render json: { error: "Só é possível dar feedback em um treino concluído" },
               status: :unprocessable_content
      end

      # Best-effort push ao aluno — mesmo padrão de
      # WorkoutsController#notify_student_of_new_workout.
      def notify_student_of_feedback(feedback)
        student_user = @student.user
        return if student_user.blank?

        PushNotificationJob.perform_later(
          student_user.id,
          title: "Feedback do seu Personal",
          body: feedback.message.truncate(120),
          url: "/aluno/assiduidade"
        )
      end
    end
  end
end
