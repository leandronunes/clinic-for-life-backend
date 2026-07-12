class WorkoutCheckInSerializer
  def initialize(check_in)
    @check_in = check_in
  end

  def as_json(*)
    {
      id: @check_in.id.to_s,
      workout_id: @check_in.workout_id.to_s,
      workout_title: @check_in.workout.title,
      status: @check_in.status,
      exercises_completed: @check_in.exercises_completed_count,
      exercises_total: @check_in.exercises_total,
      completed_exercise_ids: @check_in.exercise_check_ins.map { |ec| ec.exercise_id.to_s },
      started_at: @check_in.created_at&.iso8601,
      completed_at: @check_in.completed_at&.iso8601
    }
  end
end
