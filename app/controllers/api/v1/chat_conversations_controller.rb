module Api
  module V1
    class ChatConversationsController < BaseController
      # GET /api/v1/chat/conversations
      def index
        students = visible_students
        messages_by_student = ChatMessage.where(student_id: students.map(&:id)).group_by(&:student_id)
        viewer_role = current_user.chat_role

        # Sort on the raw Time (microsecond precision) rather than the
        # serialized ISO8601 string (whole-second precision) — two
        # conversations updated within the same second would tie as
        # strings, and .reverse on a tied, stable sort silently swaps
        # their relative order.
        conversations = students.map do |student|
          messages = messages_by_student[student.id] || []
          {
            updated_at: messages.max_by(&:created_at)&.created_at || student.created_at,
            json: ChatConversationSerializer.new(student, messages: messages, viewer_role: viewer_role).as_json
          }
        end

        render_data(conversations.sort_by { |c| c[:updated_at] }.reverse.map { |c| c[:json] })
      end

      private

      def visible_students
        return Student.all if current_user.admin?
        return Student.where(trainer_id: current_user.trainer_id) if current_user.personal?

        Student.where(id: current_user.student_id)
      end
    end
  end
end
