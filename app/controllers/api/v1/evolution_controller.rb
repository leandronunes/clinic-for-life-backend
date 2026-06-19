module Api
  module V1
    class EvolutionController < BaseController
      include StudentScoped

      # GET /api/v1/students/:student_id/evolution
      def index
        measurements = @student.bioimpedance_measurements
                               .includes(:evolution_photo)
                               .order(:measured_on)
        render_data(measurements.map { |m| BioimpedanceMeasurementSerializer.new(m).as_json })
      end

      # GET /api/v1/students/:student_id/evolution/photos
      def photos
        photos = @student.evolution_photos.order(:taken_on)
        render_data(photos.map { |p| EvolutionPhotoSerializer.new(p).as_json })
      end

      # POST /api/v1/students/:student_id/evolution/photos
      def create_photo
        measurement = @student.bioimpedance_measurements
                              .find_by(id: params[:bioimpedance_measurement_id])

        unless measurement
          return render json: { error: "Medição não encontrada para este aluno" },
                        status: :unprocessable_content
        end

        if measurement.evolution_photo.present?
          return render json: { error: "Esta medição já possui uma foto associada" },
                        status: :unprocessable_content
        end

        photo = measurement.build_evolution_photo(
          student: @student,
          image_url: params[:image_url],
          taken_on: measurement.measured_on
        )

        if photo.save
          render_data(EvolutionPhotoSerializer.new(photo).as_json, status: :created)
        else
          render json: { error: photo.errors.full_messages }, status: :unprocessable_content
        end
      end
    end
  end
end
