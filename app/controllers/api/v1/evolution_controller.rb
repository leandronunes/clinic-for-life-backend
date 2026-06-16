module Api
  module V1
    class EvolutionController < BaseController
      include StudentScoped

      # GET /api/v1/students/:student_id/evolution
      def index
        measurements = @student.bioimpedance_measurements.order(:measured_on)
        render_data(measurements.map { |m| BioimpedanceMeasurementSerializer.new(m).as_json })
      end

      # GET /api/v1/students/:student_id/evolution/photos
      def photos
        photos = @student.evolution_photos.order(:taken_on)
        render_data(photos.map { |p| EvolutionPhotoSerializer.new(p).as_json })
      end
    end
  end
end
