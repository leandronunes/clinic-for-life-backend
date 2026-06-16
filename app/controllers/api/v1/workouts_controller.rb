module Api
  module V1
    class WorkoutsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[create update archive]

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

        ActiveRecord::Base.transaction do
          # Business rule: a student has exactly one ACTIVE workout at a time.
          archive_active_workouts if workout.status == "active"
          workout.save!
          create_exercises(workout)
        end

        audit!("workout.create", record: workout)
        render_data(WorkoutSerializer.new(workout.reload).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/students/:student_id/workouts/:id
      def update
        workout = @student.workouts.find(params[:id])

        ActiveRecord::Base.transaction do
          if workout_params[:status] == "active" && workout.status != "active"
            archive_active_workouts(except: workout.id)
          end
          workout.update!(workout_params)
        end

        audit!("workout.update", record: workout)
        render_data(WorkoutSerializer.new(workout.reload).as_json)
      end

      # POST /api/v1/students/:student_id/workouts/:id/archive
      def archive
        workout = @student.workouts.find(params[:id])
        workout.archive!
        audit!("workout.archive", record: workout)
        render_data(WorkoutSerializer.new(workout).as_json)
      end

      private

      def workout_params
        params.permit(:title, :focus, :status, :position, :trainer_name)
      end

      def archive_active_workouts(except: nil)
        scope = @student.workouts.active
        scope = scope.where.not(id: except) if except
        scope.find_each(&:archive!)
      end

      def create_exercises(workout)
        return unless params.key?(:exercises)

        params.fetch(:exercises, []).each_with_index do |entry, index|
          permitted = entry.permit(:name, :sets, :reps, :load_kg, :rest_seconds,
                                   :muscle_group, :video_url, :notes, :position)
          next if permitted[:name].blank?

          permitted[:position] ||= index
          workout.exercises.create!(permitted)
        end
      end
    end
  end
end
