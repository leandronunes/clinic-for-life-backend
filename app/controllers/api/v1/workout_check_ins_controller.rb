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

        check_in = @workout.workout_check_ins.create!(
          student: @student,
          student_confirmed_at: current_user.student? ? Time.current : nil,
          personal_confirmed_at: current_user.student? ? nil : Time.current
        )
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
      #
      # Exception: once staff has confirmed a check-in (personal_confirmed_at
      # present — see #confirm), it counts toward the trainer's attendance
      # cycle, so the student can no longer delete (and thus can't silently
      # reset/overwrite) it — only admin or the owning personal can.
      def destroy
        check_in = @workout.workout_check_ins.find(params[:id])
        if check_in.personal_confirmed_at.present?
          authorize_staff_for_student!(@student)
          return if performed?
        end

        audit!("workout_check_in.destroy", record: check_in)
        check_in.destroy!
        head :no_content
      end

      # POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/confirm
      #
      # Confirms the caller's own side of the check-in: the student confirms
      # the student side, staff (admin or the owning personal) confirms the
      # personal side. Only counts toward the trainer's attendance cycle
      # once BOTH sides are confirmed (see WorkoutCheckIn#mutually_confirmed).
      # Idempotent — confirming an already-confirmed side is a no-op.
      # Authorization is entirely StudentScoped's (admin, the owning
      # personal, or the student themselves) — no extra check here, since
      # both directions are now legitimate (previously only staff could
      # call this, because only "staff confirms student" made sense).
      def confirm
        check_in = @workout.workout_check_ins.find(params[:id])
        current_user.student? ? check_in.confirm_as_student! : check_in.confirm_as_personal!
        audit!("workout_check_in.confirm", record: check_in)
        render_data(WorkoutCheckInSerializer.new(check_in).as_json)
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

      # PATCH /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/pse
      #
      # Registers the student's Percepção Subjetiva de Esforço (PSE, 1-10)
      # for a completed check-in — captured once, right after the workout is
      # finished (see docs on WorkoutCheckIn#pse). Only makes sense once the
      # check-in is completed; re-calling this is allowed (no "already set"
      # guard) so a network retry from the frontend never needs special
      # handling.
      def update_pse
        check_in = @workout.workout_check_ins.find(params[:id])
        return render_pse_requires_completed unless check_in.status == "completed"
        return render_pse_missing if params[:pse].blank?

        check_in.update!(pse: params[:pse])
        audit!("workout_check_in.update_pse", record: check_in, metadata: { pse: check_in.pse })
        render_data(WorkoutCheckInSerializer.new(check_in).as_json)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
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

      def render_pse_requires_completed
        render json: { error: "Só é possível registrar a PSE de um check-in concluído" },
               status: :unprocessable_content
      end

      def render_pse_missing
        render json: { error: "Informe a PSE (1 a 10)" }, status: :unprocessable_content
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
