module Api
  module V1
    class FeedbacksController < BaseController
      include StudentScoped

      KIND_LABELS = { "elogio" => "Elogio", "correcao" => "Correção", "incentivo" => "Incentivo" }.freeze

      before_action :require_write_access!, only: :create

      # GET /api/v1/students/:student_id/feedbacks
      def index
        feedbacks = @student.feedbacks.order(created_at: :desc)
        render_data(feedbacks.map { |f| FeedbackSerializer.new(f).as_json })
      end

      # POST /api/v1/students/:student_id/feedbacks
      def create
        feedback = @student.feedbacks.create!(feedback_params.merge(author: current_user))
        audit!("feedback.create", record: feedback)
        notify_student_of_feedback(feedback)
        render_data(FeedbackSerializer.new(feedback).as_json, status: :created)
      end

      private

      def feedback_params
        params.permit(:kind, :message)
      end

      # Best-effort push ao aluno — mesmo padrão de
      # WorkoutsController#notify_student_of_new_workout.
      def notify_student_of_feedback(feedback)
        student_user = @student.user
        return if student_user.blank?

        kind_label = KIND_LABELS.fetch(feedback.kind, "Feedback")
        PushNotificationJob.perform_later(
          student_user.id,
          title: "#{kind_label} do seu Personal",
          body: feedback.message.truncate(120),
          url: "/aluno/assiduidade"
        )
      end
    end
  end
end
