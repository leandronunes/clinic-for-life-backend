class ExerciseSerializer
  def initialize(exercise)
    @exercise = exercise
  end

  def as_json(*)
    {
      id: @exercise.id.to_s,
      position: @exercise.position,
      name: @exercise.name,
      sets: @exercise.sets,
      reps: @exercise.reps,
      load_kg: @exercise.load_kg&.to_f,
      rest_seconds: @exercise.rest_seconds,
      muscle_group: @exercise.muscle_group,
      video_url: @exercise.video_url,
      notes: @exercise.notes
    }
  end
end
