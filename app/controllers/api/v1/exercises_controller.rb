module Api
  module V1
    class ExercisesController < BaseController
      include StudentScoped
      include S3Deletable

      before_action :require_write_access!
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
        exercise.update!(exercise_params)
        audit!("exercise.update", record: exercise)
        delete_from_s3(old_video_url) if old_video_url != exercise.video_url
        render_data(ExerciseSerializer.new(exercise).as_json)
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

      def exercise_params
        params.permit(:name, :sets, :reps, :load_kg, :rest_seconds,
                      :muscle_group, :video_url, :notes, :position)
      end
    end
  end
end
