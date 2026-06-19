module Api
  module V1
    class UploadsController < BaseController
      # Rails infers the wrap key from the controller name ("upload"), causing
      # the JSON body to be duplicated under params[:upload]. Disable it here.
      wrap_parameters false

      before_action :load_and_authorize_student!

      # POST /api/v1/uploads/presign
      # Generates an S3 presigned PUT URL so the frontend can upload a file
      # directly to S3 and then store only the permanent public URL.
      def presign
        result = S3Presigner.new.presign(
          content_type: presign_params[:content_type],
          context: presign_params[:context],
          student_id: @student.id
        )
        render_data(result)
      rescue S3Presigner::InvalidParamsError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue S3Presigner::ConfigurationError
        render json: { error: "Storage not configured" }, status: :service_unavailable
      end

      private

      # Resolves the student from params and checks that the current user may
      # upload on their behalf. Students may only presign for the exam context.
      def load_and_authorize_student!
        @student = Student.find_by(id: presign_params[:student_id])
        return render json: { error: "Student not found" }, status: :not_found unless @student

        return if current_user&.admin?
        return if current_user&.personal? && @student.trainer_id == current_user.trainer_id
        return if current_user&.student? &&
                  @student.id == current_user.student_id &&
                  presign_params[:context] == "exam"

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def presign_params
        params.permit(:filename, :content_type, :context, :student_id)
      end
    end
  end
end
