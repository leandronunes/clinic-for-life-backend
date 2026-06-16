module Api
  module V1
    class ExamsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[create destroy]

      # GET /api/v1/students/:student_id/exams
      def index
        exams = @student.exams.order(uploaded_at: :desc)
        render_data(exams.map { |e| ExamSerializer.new(e).as_json })
      end

      # POST /api/v1/students/:student_id/exams
      def create
        exam = @student.exams.new(exam_params)
        exam.save!
        audit!("exam.create", record: exam)
        render_data(ExamSerializer.new(exam).as_json, status: :created)
      end

      # DELETE /api/v1/students/:student_id/exams/:id
      def destroy
        exam = @student.exams.find(params[:id])
        exam.destroy!
        audit!("exam.destroy", record: exam)
        head :no_content
      end

      private

      def exam_params
        params.permit(:name, :description, :file_url, :content_type, :size, :uploaded_at)
      end
    end
  end
end
