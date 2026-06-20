module Api
  module V1
    class BioimpedanceMeasurementsController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[create destroy]

      # GET /api/v1/students/:student_id/bioimpedance_measurements
      def index
        measurements = @student.bioimpedance_measurements.order(:measured_on)
        render_data(measurements.map { |m| BioimpedanceMeasurementSerializer.new(m).as_json })
      end

      # POST /api/v1/students/:student_id/bioimpedance_measurements
      def create
        measurement = @student.bioimpedance_measurements.new(measurement_params)
        measurement.source ||= "manual"
        measurement.save!
        audit!("bioimpedance_measurement.create", record: measurement)
        render_data(BioimpedanceMeasurementSerializer.new(measurement).as_json, status: :created)
      end

      # DELETE /api/v1/students/:student_id/bioimpedance_measurements/:id
      def destroy
        measurement = @student.bioimpedance_measurements.find(params[:id])
        measurement.destroy!
        audit!("bioimpedance_measurement.destroy", record: measurement)
        head :no_content
      end

      private

      def measurement_params
        params.permit(:weight_kg, :muscle_mass_kg, :fat_percentage, :visceral_fat,
                      :bmi, :measured_on, :source)
      end
    end
  end
end
