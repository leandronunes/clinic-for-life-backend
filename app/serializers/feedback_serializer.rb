class FeedbackSerializer
  def initialize(feedback)
    @feedback = feedback
  end

  def as_json(*)
    {
      id: @feedback.id.to_s,
      workout_check_in_id: @feedback.workout_check_in_id.to_s,
      kind: @feedback.kind,
      message: @feedback.message,
      author_name: @feedback.author&.name,
      created_at: @feedback.created_at&.iso8601
    }
  end
end
