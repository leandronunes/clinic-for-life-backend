class WorkoutReactionSerializer
  def initialize(reaction)
    @reaction = reaction
  end

  def as_json(*)
    {
      id: @reaction.id.to_s,
      emoji: @reaction.emoji,
      author_name: @reaction.author&.name,
      created_at: @reaction.created_at&.iso8601
    }
  end
end
