module Api
  module V1
    class BiomechanicalAssessmentsController < BaseController
      include StudentScoped
      include S3Deletable

      before_action :require_write_access!, only: %i[new_assessment upload remove_image]

      # GET /api/v1/students/:student_id/biomechanical_assessments
      def index
        assessments = @student.biomechanical_assessments.order(created_at: :desc)
        render_data(assessments.map { |a| BiomechanicalAssessmentSerializer.new(a).as_json })
      end

      # GET /api/v1/students/:student_id/biomechanical_assessments/current
      def current
        assessment = current_assessment
        render_data(BiomechanicalAssessmentSerializer.new(assessment).as_json)
      end

      # POST /api/v1/students/:student_id/biomechanical_assessments/new_assessment
      def new_assessment
        assessment = @student.biomechanical_assessments.create!
        audit!("biomechanical_assessment.create", record: assessment)
        render_data(BiomechanicalAssessmentSerializer.new(assessment).as_json, status: :created)
      end

      # PUT /api/v1/students/:student_id/biomechanical_assessments/upload
      def upload
        slot = params.require(:slot)
        unless BiomechanicalImage::SLOTS.include?(slot)
          return render json: { error: "Invalid slot" }, status: :unprocessable_entity
        end

        assessment = current_assessment
        image = assessment.biomechanical_images.find_or_initialize_by(slot: slot)
        old_image_url = image.image_url
        # The client's `image_url` may be the presigned GET URL echoed back
        # from a previous read (see BiomechanicalAssessmentSerializer) —
        # canonicalize it so it doesn't get persisted with a query string,
        # and so an unchanged image isn't mistaken for a new one below.
        image.image_url = S3Presigner.canonicalize(params.require(:image_url))
        image.save!
        delete_from_s3(old_image_url) if old_image_url != image.image_url
        audit!("biomechanical_assessment.upload", record: assessment, metadata: { slot: slot })
        render_data(BiomechanicalAssessmentSerializer.new(assessment.reload).as_json)
      end

      # DELETE /api/v1/students/:student_id/biomechanical_assessments/remove_image
      def remove_image
        assessment = current_assessment
        assessment.biomechanical_images.where(slot: params.require(:slot)).destroy_all
        audit!("biomechanical_assessment.remove_image", record: assessment,
               metadata: { slot: params[:slot] })
        render_data(BiomechanicalAssessmentSerializer.new(assessment.reload).as_json)
      end

      private

      def current_assessment
        @student.biomechanical_assessments.order(created_at: :desc).first ||
          @student.biomechanical_assessments.create!
      end
    end
  end
end
