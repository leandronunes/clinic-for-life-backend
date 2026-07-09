module Api
  module V1
    class WorkoutsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[create update destroy archive unarchive reorder]

      # GET /api/v1/students/:student_id/workouts
      def index
        workouts = @student.workouts.order(:position, :id)
        workouts = workouts.where(status: params[:status]) if params[:status].present?
        render_data(workouts.map { |w| WorkoutSerializer.new(w).as_json })
      end

      # POST /api/v1/students/:student_id/workouts
      def create
        workout = @student.workouts.new(workout_params)
        workout.status ||= "active"
        workout.trainer_name ||= current_user.name
        workout.position = workout_params[:position].presence&.to_i ||
                           @student.workouts.active.maximum(:position).to_i + 1

        ActiveRecord::Base.transaction do
          workout.save!
          create_exercises(workout)
        end

        audit!("workout.create", record: workout)
        notify_student_of_new_workout(workout)
        render_data(WorkoutSerializer.new(workout.reload).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/students/:student_id/workouts/:id
      def update
        workout = @student.workouts.find(params[:id])
        workout.update!(workout_params)
        audit!("workout.update", record: workout)
        render_data(WorkoutSerializer.new(workout.reload).as_json)
      end

      # DELETE /api/v1/students/:student_id/workouts/:id
      def destroy
        workout = @student.workouts.find(params[:id])
        status = workout.status
        workout.destroy!
        renumber_positions!(status)
        audit!("workout.destroy", record: workout)
        head :no_content
      end

      # POST /api/v1/students/:student_id/workouts/:id/archive
      def archive
        workout = @student.workouts.find(params[:id])
        workout.archive!
        audit!("workout.archive", record: workout)
        render_data(WorkoutSerializer.new(workout).as_json)
      end

      # POST /api/v1/students/:student_id/workouts/:id/unarchive
      def unarchive
        workout = @student.workouts.find(params[:id])
        unless workout.archived?
          return render json: { error: "Treino não está arquivado" }, status: :unprocessable_content
        end
        workout.unarchive!
        audit!("workout.unarchive", record: workout)
        render_data(WorkoutSerializer.new(workout).as_json)
      end

      # PATCH /api/v1/students/:student_id/workouts/reorder
      def reorder
        ordered_ids = Array(params[:ordered_ids])
        # Two-phase update to avoid transient unique-constraint violations:
        # phase 1 moves all positions out of range, phase 2 sets final values.
        offset = 10_000
        ActiveRecord::Base.transaction do
          ordered_ids.each_with_index do |id, idx|
            @student.workouts.where(id: id).update_all(position: offset + idx + 1)
          end
          ordered_ids.each_with_index do |id, idx|
            @student.workouts.where(id: id).update_all(position: idx + 1)
          end
        end
        audit!("workout.reorder", record: @student)
        workouts = @student.workouts.order(:position, :id)
        render_data(workouts.map { |w| WorkoutSerializer.new(w).as_json })
      end

      private

      # Best-effort push notification to the student's linked login, if any.
      # Enqueued via ActiveJob so the network call to the push service never
      # blocks this request/response cycle.
      def notify_student_of_new_workout(workout)
        return unless workout.status == "active"

        student_user = @student.user
        return if student_user.blank?

        PushNotificationJob.perform_later(
          student_user.id,
          title: "Novo treino criado!",
          body: "O seu personal #{workout.trainer_name} criou um novo treino para você.",
          url: "/aluno?workout=#{workout.id}"
        )
      end

      # Closes the gap a deleted workout leaves behind so a student's
      # remaining workouts (within the same status group) stay a dense,
      # 1-based sequence — same two-phase offset trick as #reorder, to avoid
      # transient unique-constraint violations on (student_id, position).
      def renumber_positions!(status)
        ids_in_order = @student.workouts.where(status: status).order(:position, :id).pluck(:id)
        offset = 10_000
        ActiveRecord::Base.transaction do
          ids_in_order.each_with_index do |id, idx|
            @student.workouts.where(id: id).update_all(position: offset + idx + 1)
          end
          ids_in_order.each_with_index do |id, idx|
            @student.workouts.where(id: id).update_all(position: idx + 1)
          end
        end
      end

      def workout_params
        params.permit(:title, :focus, :status, :position, :trainer_name)
      end

      def create_exercises(workout)
        return unless params.key?(:exercises)

        params.fetch(:exercises, []).each_with_index do |entry, index|
          permitted = entry.permit(:kind, :name, :sets, :reps, :load_kg, :rest_seconds,
                                   :muscle_group, :video_url, :notes, :position,
                                   :duration_seconds, :distance_value, :distance_unit,
                                   :hr_zone, :heart_rate_bpm)
          next if permitted[:name].blank?

          permitted[:position] ||= index
          workout.exercises.create!(permitted)
        end
      end
    end
  end
end
