class AttendanceCycleSerializer
  def initialize(cycle)
    @cycle = cycle
  end

  def as_json(*)
    contracted = @cycle.contracted_workouts_per_cycle
    completed = @cycle.completed_workouts
    {
      id: @cycle.id.to_s,
      student_id: @cycle.student_id.to_s,
      contracted_workouts_per_cycle: contracted,
      completed_workouts: completed,
      percentage: contracted.positive? ? ((completed.to_f / contracted) * 100).round : 0,
      status: completed > contracted ? "exceeded" : "completed",
      started_at: @cycle.started_at.iso8601,
      ended_at: @cycle.ended_at.iso8601
    }
  end
end
