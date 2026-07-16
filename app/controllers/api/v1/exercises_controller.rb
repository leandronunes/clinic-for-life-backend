module Api
  module V1
    class ExercisesController < BaseController
      include StudentScoped
      include S3Deletable

      # update is deliberately excluded: a student may PATCH their own
      # exercise, but only to record the load they actually used (see
      # #update and #student_exercise_params) — StudentScoped's
      # authorize_student! (admin, owning personal, or the student
      # themselves) is the only gate for that action.
      before_action :require_write_access!, only: %i[create destroy reorder]
      before_action :set_workout

      # POST /api/v1/students/:student_id/workouts/:workout_id/exercises
      def create
        exercise = @workout.exercises.new(exercise_params)
        exercise.position ||= @workout.exercises.maximum(:position).to_i + 1
        exercise.save!
        audit!("exercise.create", record: exercise)
        render_data(ExerciseSerializer.new(exercise).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/students/:student_id/workouts/:workout_id/exercises/:id
      def update
        exercise = @workout.exercises.find(params[:id])
        old_video_url = exercise.video_url
        exercise.update!(current_user.student? ? student_exercise_params : exercise_params)
        audit!("exercise.update", record: exercise)
        delete_from_s3(old_video_url) if old_video_url != exercise.video_url
        render_data(ExerciseSerializer.new(exercise).as_json)
      end

      # PATCH /api/v1/students/:student_id/workouts/:workout_id/exercises/reorder
      def reorder
        ordered_ids = Array(params[:ordered_ids])
        ActiveRecord::Base.transaction do
          ordered_ids.each_with_index do |id, idx|
            @workout.exercises.where(id: id).update_all(position: idx + 1)
          end
        end
        audit!("exercise.reorder", record: @workout)
        render_data(@workout.exercises.reload.map { |e| ExerciseSerializer.new(e).as_json })
      end

      # DELETE /api/v1/students/:student_id/workouts/:workout_id/exercises/:id
      def destroy
        exercise = @workout.exercises.find(params[:id])
        exercise.destroy!
        audit!("exercise.destroy", record: exercise)
        head :no_content
      end

      private

      def set_workout
        @workout = @student.workouts.find(params[:workout_id])
      end

      # A student editing their own exercise from the execution screen may
      # only touch the load they used — the workout's structure (sets,
      # reps, rest, video, etc.) stays personal/admin-only.
      def student_exercise_params
        params.permit(:load_kg)
      end

      def exercise_params
        params.permit(:kind, :name, :sets, :reps, :load_kg, :rest_seconds,
                      :muscle_group, :video_url, :notes, :position,
                      :duration_seconds, :distance_value, :distance_unit,
                      :hr_zone, :heart_rate_bpm).tap do |attrs|
          # The client's `video_url` may be the presigned GET URL echoed back
          # from a previous read (see ExerciseSerializer) — canonicalize it so
          # it doesn't get persisted with a query string, and so an unchanged
          # video isn't mistaken for a new one below (see `old_video_url`).
          attrs[:video_url] = S3Presigner.canonicalize(attrs[:video_url]) if attrs[:video_url]
        end
      end
    end
  end
end
