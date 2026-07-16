module Api
  module V1
    class WorkoutCheckInsController < BaseController
      include StudentScoped

      before_action :set_workout, except: :index
      rescue_from ActiveRecord::RecordNotUnique, with: :render_duplicate_check_in

      # GET /api/v1/students/:student_id/check_ins
      def index
        check_ins = @student.workout_check_ins
                             .includes(:workout, :student, :exercise_check_ins,
                                       check_in_feedbacks: :author)
                             .order(created_at: :desc)
        render_data(check_ins.map { |c| WorkoutCheckInSerializer.new(c).as_json })
      end

      # GET /api/v1/students/:student_id/workouts/:workout_id/check_ins/current
      #
      # "Current" means "what the aluno sees instead of a bare 'Iniciar
      # treino' button": the in-progress check-in if there is one, otherwise
      # today's completed one (if any) — so the frontend can show "já
      # concluído hoje" instead of silently letting a second one start.
      def current
        check_in = @workout.workout_check_ins.in_progress.first || today_completed_check_in
        render_data(check_in ? WorkoutCheckInSerializer.new(check_in).as_json : nil)
      end

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins
      def create
        if @workout.archived?
          return render json: { error: "Treino arquivado é somente leitura" }, status: :unprocessable_content
        end
        if today_completed_check_in
          return render json: {
            error: "Este treino já foi concluído hoje. Remova o check-in para refazê-lo."
          }, status: :unprocessable_content
        end

        check_in = @workout.workout_check_ins.create!(student: @student)
        audit!("workout_check_in.create", record: check_in)
        render_data(WorkoutCheckInSerializer.new(check_in).as_json, status: :created)
      end

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/finish
      def finish
        check_in = @workout.workout_check_ins.find(params[:id])
        return already_finished if check_in.status == "completed"

        check_in.finish!
        audit!("workout_check_in.finish", record: check_in)
        notify_trainer_of_completion(check_in)
        render_data(WorkoutCheckInSerializer.new(check_in).as_json)
      end

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/view
      def view
        check_in = @workout.workout_check_ins.find(params[:id])
        check_in.mark_viewed!
        render_data(WorkoutCheckInSerializer.new(check_in).as_json)
      end

      # DELETE /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id
      #
      # Lets the student remove a mistaken check-in from their own history
      # (e.g. started a workout by accident, or wants a bad session gone) —
      # same authorization as every other action here (StudentScoped already
      # covers admin, the owning personal, and the student themselves).
      def destroy
        check_in = @workout.workout_check_ins.find(params[:id])
        audit!("workout_check_in.destroy", record: check_in)
        check_in.destroy!
        head :no_content
      end

      # PATCH /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/exercises/:exercise_id
      def toggle_exercise
        check_in = @workout.workout_check_ins.find(params[:id])
        return already_finished if check_in.status == "completed"

        exercise = @workout.exercises.find(params[:exercise_id])
        completed = ActiveModel::Type::Boolean.new.cast(params[:completed])

        if completed
          check_in.exercise_check_ins.find_or_create_by!(exercise: exercise) { |ec| ec.completed_at = Time.current }
        else
          check_in.exercise_check_ins.find_by(exercise: exercise)&.destroy
        end

        check_in.maybe_auto_finish!
        audit!("workout_check_in.toggle_exercise", record: check_in,
               metadata: { exercise_id: exercise.id.to_s, completed: completed })
        notify_trainer_of_completion(check_in) if check_in.status == "completed"

        render_data(WorkoutCheckInSerializer.new(check_in.reload).as_json)
      end

      private

      def set_workout
        @workout = @student.workouts.find(params[:workout_id])
      end

      # A workout only makes sense to check into once a day — this backs
      # both #current (so the UI shows "já concluído hoje" instead of a
      # stale "Iniciar treino") and #create (so that state is actually
      # enforced, not just hidden client-side).
      def today_completed_check_in
        @workout.workout_check_ins.completed.where(completed_at: Time.zone.now.all_day).first
      end

      def already_finished
        render json: { error: "Check-in já finalizado" }, status: :unprocessable_content
      end

      def render_duplicate_check_in
        render json: { error: "Já existe um check-in em andamento para este treino" },
               status: :unprocessable_content
      end

      # Best-effort push ao personal — mesmo padrão de
      # WorkoutsController#notify_student_of_new_workout. Só dispara se pelo
      # menos um exercício foi concluído (sessão zerada não merece alertar).
      def notify_trainer_of_completion(check_in)
        return if check_in.exercises_completed_count.zero?

        trainer_user = check_in.student.trainer&.user
        return if trainer_user.blank?

        PushNotificationJob.perform_later(
          trainer_user.id,
          title: "Check-in concluído",
          body: "#{check_in.student.name} concluiu o check-in do treino \"#{check_in.workout.title}\".",
          url: "/alunos/#{check_in.student.id}"
        )
      end
    end
  end
end
