module Api
  module V1
    class AttendanceCyclesController < BaseController
      include StudentScoped

      # GET /api/v1/students/:student_id/attendance_cycles
      def index
        cycles = @student.attendance_cycles.order(ended_at: :desc)
        render_data(cycles.map { |cycle| AttendanceCycleSerializer.new(cycle).as_json })
      end
    end
  end
end
