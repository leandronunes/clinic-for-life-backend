class WorkoutSerializer
  def initialize(workout)
    @workout = workout
  end

  def as_json(*)
    {
      id: @workout.id.to_s,
      position: @workout.position,
      title: @workout.title,
      focus: @workout.focus,
      status: @workout.status,
      created_at: @workout.created_at&.to_date&.iso8601,
      archived_at: @workout.archived_at&.to_date&.iso8601,
      exercises: @workout.exercises.map { |exercise| ExerciseSerializer.new(exercise).as_json }
    }
  end
end
