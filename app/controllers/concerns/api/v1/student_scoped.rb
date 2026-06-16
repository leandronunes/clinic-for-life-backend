module Api
  module V1
    # Shared helpers for controllers nested under /students/:student_id.
    module StudentScoped
      extend ActiveSupport::Concern

      included do
        before_action :set_student_and_authorize
      end

      private

      def set_student_and_authorize
        @student = Student.find(params[:student_id])
        authorize_student!(@student)
      end
    end
  end
end
