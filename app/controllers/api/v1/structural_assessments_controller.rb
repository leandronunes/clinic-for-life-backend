module Api
  module V1
    class StructuralAssessmentsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[update]

      # GET /api/v1/students/:student_id/structural_assessment
      def show
        assessment = @student.structural_assessment || @student.build_structural_assessment
        render_data(StructuralAssessmentSerializer.new(assessment).as_json)
      end

      # PATCH/PUT /api/v1/students/:student_id/structural_assessment
      def update
        assessment = @student.structural_assessment || @student.build_structural_assessment
        assessment.assign_attributes(structural_params)
        assessment.save!
        audit!("structural_assessment.update", record: assessment)
        render_data(StructuralAssessmentSerializer.new(assessment).as_json)
      end

      private

      def structural_params
        params.permit(*StructuralAssessment::ITEMS)
      end
    end
  end
end
