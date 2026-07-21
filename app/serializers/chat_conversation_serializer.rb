# Takes the student's already-loaded messages (see ChatConversationsController)
# rather than querying here, so listing N conversations only ever costs one
# query for the messages of all of them, not N.
class ChatConversationSerializer
  def initialize(student, messages:, viewer_role:)
    @student = student
    @messages = messages
    @viewer_role = viewer_role
  end

  def as_json(*)
    last = @messages.max_by(&:created_at)
    {
      student_id: @student.id.to_s,
      student_name: @student.name,
      student_avatar_url: @student.user&.avatar_url,
      trainer_id: @student.trainer_id&.to_s,
      trainer_name: @student.trainer_name,
      last_message: last && ChatMessageSerializer.new(last).as_json,
      unread_count: @messages.count { |m| m.sender_role != @viewer_role && m.read_at.nil? },
      updated_at: (last&.created_at || @student.created_at).iso8601
    }
  end
end
