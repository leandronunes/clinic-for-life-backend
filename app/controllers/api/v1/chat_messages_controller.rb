module Api
  module V1
    class ChatMessagesController < BaseController
      include StudentScoped

      # GET /api/v1/chat/conversations/:student_id/messages
      def index
        messages = @student.chat_messages.order(:created_at)
        render_data(messages.map { |m| ChatMessageSerializer.new(m).as_json })
      end

      # POST /api/v1/chat/conversations/:student_id/messages
      def create
        message = @student.chat_messages.create!(
          chat_message_params.merge(sender: current_user, sender_role: current_user.chat_role)
        )
        audit!("chat_message.create", record: message)
        render_data(ChatMessageSerializer.new(message).as_json, status: :created)
      end

      # POST /api/v1/chat/conversations/:student_id/read
      # Always 200, even when nothing was pending — the client calls this
      # best-effort every time a conversation is opened/refreshed.
      def read
        read_count = @student.chat_messages.unread_for(current_user.chat_role).update_all(read_at: Time.current)
        render_data({ read: read_count })
      end

      private

      def chat_message_params
        params.permit(:body)
      end
    end
  end
end
