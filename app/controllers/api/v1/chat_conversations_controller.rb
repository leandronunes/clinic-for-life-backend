module Api
  module V1
    class ChatConversationsController < BaseController
      # GET /api/v1/chat/conversations
      def index
        students = visible_students
        messages_by_student = ChatMessage.where(student_id: students.map(&:id)).group_by(&:student_id)
        viewer_role = current_user.chat_role

        conversations = students.map do |student|
          ChatConversationSerializer.new(
            student,
            messages: messages_by_student[student.id] || [],
            viewer_role: viewer_role
          ).as_json
        end

        render_data(conversations.sort_by { |c| c[:updated_at] }.reverse)
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
