module Api
  module V1
    class UploadsController < BaseController
      # Rails infers the wrap key from the controller name ("upload"), causing
      # the JSON body to be duplicated under params[:upload]. Disable it here.
      wrap_parameters false

      before_action :authorize_presign!

      # POST /api/v1/uploads/presign
      # Generates an S3 presigned PUT URL so the frontend can upload a file
      # directly to S3 and then store only the permanent public URL.
      def presign
        result = S3Presigner.new.presign(
          content_type: presign_params[:content_type],
          context: presign_params[:context]
        )
        render_data(result)
      rescue S3Presigner::InvalidParamsError => e
        render json: { error: e.message }, status: :unprocessable_content
      rescue S3Presigner::ConfigurationError
        render json: { error: "Storage not configured" }, status: :service_unavailable
      end

      private

      # Students may presign only for the exam context (their own uploads).
      # Admins and personals may presign for any context.
      def authorize_presign!
        return if current_user&.admin? || current_user&.personal?
        return if current_user&.student? && presign_params[:context] == "exam"

        render json: { error: "Forbidden" }, status: :forbidden
      end

      def presign_params
        params.permit(:filename, :content_type, :context)
      end
    end
  end
end
