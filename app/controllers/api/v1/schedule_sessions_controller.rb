module Api
  module V1
    class ScheduleSessionsController < BaseController
      before_action :set_session, only: %i[update destroy]

      # GET /api/v1/schedule_sessions?from=&to=&trainer_id=&student_id=
      def index
        if params[:from].blank? || params[:to].blank?
          return render json: { error: "Parâmetros from e to são obrigatórios" },
                        status: :unprocessable_content
        end

        from_range = ScheduleExpansionService.day_range(params[:from])
        to_range = ScheduleExpansionService.day_range(params[:to])

        sessions = session_scope.where(starts_at: from_range.begin..to_range.end)
        sessions = sessions.where(trainer_id: params[:trainer_id]) if allow_trainer_filter?
        sessions = sessions.where(student_id: params[:student_id]) if allow_student_filter?
        sessions = sessions.includes(:student, :trainer).order(:starts_at)

        render_data(sessions.map { |s| ScheduleSessionSerializer.new(s).as_json })
      end

      # PATCH /api/v1/schedule_sessions/:id
      def update
        authorize_staff_for_student!(@session.student)
        return if performed?

        @session.update!(session_params)
        audit!("schedule_session.update", record: @session)
        render_data(ScheduleSessionSerializer.new(@session.reload).as_json)
      end

      # DELETE /api/v1/schedule_sessions/:id
      def destroy
        authorize_staff_for_student!(@session.student)
        return if performed?

        audit!("schedule_session.destroy", record: @session)
        @session.destroy!
        head :no_content
      end

      private

      def set_session
        @session = ScheduleSession.find(params[:id])
      end

      # Personal só vê seu próprio portfólio; aluno só a própria agenda;
      # admin vê tudo (e pode filtrar por trainer_id/student_id via query).
      def session_scope
        return ScheduleSession.where(trainer_id: current_user.trainer_id) if current_user.personal?
        return ScheduleSession.where(student_id: current_user.student_id) if current_user.student?

        ScheduleSession.all
      end

      def allow_trainer_filter?
        current_user.admin? && params[:trainer_id].present?
      end

      def allow_student_filter?
        !current_user.student? && params[:student_id].present?
      end

      def session_params
        params.permit(:starts_at, :duration_minutes, :status, :notes)
      end
    end
  end
end
