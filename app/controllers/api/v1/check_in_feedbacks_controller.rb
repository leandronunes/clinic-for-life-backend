module Api
  module V1
    class CheckInFeedbacksController < BaseController
      include StudentScoped

      before_action :require_write_access!
      before_action :set_workout
      before_action :set_check_in
      before_action :set_feedback, only: %i[update destroy]

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:check_in_id/feedbacks
      def create
        return render_not_completed unless @check_in.status == "completed"

        feedback = @check_in.check_in_feedbacks.create!(feedback_params.merge(author: current_user))
        audit!("check_in_feedback.create", record: feedback)
        notify_student(feedback)
        render_data(CheckInFeedbackSerializer.new(feedback).as_json, status: :created)
      end

      # PATCH /api/v1/students/:student_id/workouts/:workout_id/check_ins/:check_in_id/feedbacks/:id
      def update
        authorize_author!
        @feedback.update!(feedback_params)
        audit!("check_in_feedback.update", record: @feedback)
        render_data(CheckInFeedbackSerializer.new(@feedback).as_json)
      end

      # DELETE /api/v1/students/:student_id/workouts/:workout_id/check_ins/:check_in_id/feedbacks/:id
      def destroy
        authorize_author!
        @feedback.destroy!
        audit!("check_in_feedback.destroy", record: @feedback)
        head :no_content
      end

      private

      def set_workout
        @workout = @student.workouts.find(params[:workout_id])
      end

      def set_check_in
        @check_in = @workout.workout_check_ins.find(params[:check_in_id])
      end

      def set_feedback
        @feedback = @check_in.check_in_feedbacks.find(params[:id])
      end

      def authorize_author!
        return if current_user.admin? || @feedback.author_id == current_user.id

        render json: { error: "Não autorizado" }, status: :forbidden
      end

      def feedback_params
        params.permit(:emoji, :message)
      end

      def render_not_completed
        render json: { error: "Só é possível dar feedback em um treino concluído" },
               status: :unprocessable_content
      end

      def notify_student(feedback)
        student_user = @student.user
        return if student_user.blank?

        title, body = if feedback.emoji.present? && feedback.message.present?
          [ "Feedback do seu Personal",
            "#{feedback.emoji} #{feedback.message.truncate(100)}" ]
        elsif feedback.emoji.present?
          [ "Seu personal reagiu ao seu treino!",
            "#{feedback.emoji} no treino \"#{@check_in.workout.title}\"." ]
        else
          [ "Feedback do seu Personal", feedback.message.truncate(120) ]
        end

        PushNotificationJob.perform_later(
          student_user.id,
          title: title,
          body: body,
          url: "/aluno/assiduidade"
        )
      end
    end
  end
end
