class ChatMessageSerializer
  def initialize(message)
    @message = message
  end

  def as_json(*)
    {
      id: @message.id.to_s,
      student_id: @message.student_id.to_s,
      sender_role: @message.sender_role,
      sender_id: @message.sender_id.to_s,
      sender_name: @message.sender&.name,
      body: @message.body,
      created_at: @message.created_at&.iso8601,
      read_at: @message.read_at&.iso8601
    }
  end
end
