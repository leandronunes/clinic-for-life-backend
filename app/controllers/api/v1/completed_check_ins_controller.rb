module Api
  module V1
    class CompletedCheckInsController < BaseController
      before_action -> { require_role!(:admin, :personal) }

      # GET /api/v1/completed_check_ins
      def index
        check_ins = WorkoutCheckIn.completed.where(student: student_scope)
                                   .includes(:student, :workout, check_in_feedbacks: :author)
                                   .order(completed_at: :desc)
        render_data(check_ins.map { |c| WorkoutCheckInSerializer.new(c).as_json })
      end
    end
  end
end
