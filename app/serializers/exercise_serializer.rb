class ExerciseSerializer
  def initialize(exercise)
    @exercise = exercise
  end

  def as_json(*)
    {
      id: @exercise.id.to_s,
      position: @exercise.position,
      kind: @exercise.kind,
      name: @exercise.name,
      sets: @exercise.sets,
      reps: @exercise.reps,
      load_kg: @exercise.load_kg&.to_f,
      rest_seconds: @exercise.rest_seconds,
      muscle_group: @exercise.muscle_group,
      duration_seconds: @exercise.duration_seconds,
      distance_value: @exercise.distance_value&.to_f,
      distance_unit: @exercise.distance_unit,
      hr_zone: @exercise.hr_zone,
      heart_rate_bpm: @exercise.heart_rate_bpm,
      video_url: S3Presigner.presign_get_for(@exercise.video_url),
      notes: @exercise.notes
    }
  end
end
