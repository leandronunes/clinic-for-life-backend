module Api
  module V1
    class AnamnesesController < BaseController
      include StudentScoped

      before_action :require_write_access!, only: %i[update]

      # GET /api/v1/students/:student_id/anamnesis
      def show
        anamnesis = @student.anamnesis || @student.build_anamnesis
        render_data(AnamnesisSerializer.new(anamnesis).as_json)
      end

      # PATCH/PUT /api/v1/students/:student_id/anamnesis
      def update
        anamnesis = @student.anamnesis || @student.build_anamnesis
        anamnesis.assign_attributes(anamnesis_params)
        anamnesis.save!
        sync_external_professionals(anamnesis)
        audit!("anamnesis.update", record: anamnesis)
        render_data(AnamnesisSerializer.new(anamnesis.reload).as_json)
      end

      private

      def anamnesis_params
        params.permit(*Anamnesis::FIELDS)
      end

      def sync_external_professionals(anamnesis)
        return unless params.key?(:external_professionals)

        entries = Array.wrap(params[:external_professionals])
        anamnesis.external_professionals.destroy_all
        entries.each do |entry|
          permitted = entry.permit(:name, :specialty, :objective)
          next if permitted[:name].blank?

          anamnesis.external_professionals.create!(permitted)
        end
      end
    end
  end
end
