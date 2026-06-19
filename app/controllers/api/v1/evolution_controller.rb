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

      # POST /api/v1/students/:student_id/evolution/photos
      def create_photo
        photo = @student.evolution_photos.build(photo_params)
        if photo.save
          render_data(EvolutionPhotoSerializer.new(photo).as_json, status: :created)
        else
          render json: { error: photo.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def photo_params
        params.permit(:taken_on, :image_url, :weight_kg, :fat_percentage, :muscle_mass_kg)
      end
    end
  end
end
