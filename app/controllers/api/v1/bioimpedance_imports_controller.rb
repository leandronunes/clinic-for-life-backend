require "csv"

module Api
  module V1
    # Handles CSV import of bioimpedance measurements exported by InBody devices.
    # The student is identified by the student_id param — the CSV has no patient info.
    class BioimpedanceImportsController < BaseController
      before_action :require_write_access!

      # POST /api/v1/bioimpedance/import
      def create
        content = read_payload
        return render_import_error("File is required") if content.blank?

        student = Student.find_by(id: import_params[:student_id])
        return render_import_error("Aluno não encontrado") unless student
        return render json: { error: "Forbidden" }, status: :forbidden unless authorize_for_import(student)

        rows = InbodyCsvParser.parse(content)
        return render_import_error("Formato de CSV inválido ou não reconhecido como InBody") if rows.nil?
        return render_import_error("Nenhuma linha válida encontrada no arquivo") if rows.empty?

        result = persist_rows(student, rows)

        BioimpedanceImport.create!(
          trainer_id:     current_user.trainer_id,
          filename:       import_params[:filename].presence || "import.csv",
          total_rows:     rows.size,
          imported_count: result[:imported],
          errors_log:     result[:errors]
        )
        audit!("bioimpedance.import", metadata: { student_id: student.id, imported: result[:imported], failed: result[:errors].size })

        render_data(
          {
            imported: result[:imported],
            errors:   result[:errors],
            preview:  result[:preview].map { |m| BioimpedanceMeasurementSerializer.new(m).as_json }
          },
          status: :created
        )
      end

      private

      def persist_rows(student, rows)
        imported = 0
        errors   = []
        preview  = []

        rows.each_with_index do |row, idx|
          m = student.bioimpedance_measurements.new(
            measured_on:    row.measured_on,
            weight_kg:      row.weight_kg,
            muscle_mass_kg: row.muscle_mass_kg,
            fat_percentage: row.fat_percentage,
            bmi:            row.bmi,
            visceral_fat:   row.visceral_fat,
            source:         "import"
          )

          if m.save
            imported += 1
            preview  << m
          else
            errors << "Linha #{idx + 2}: #{m.errors.full_messages.join(', ')}"
          end
        end

        { imported: imported, errors: errors, preview: preview }
      end

      def read_payload
        if params[:file].respond_to?(:read)
          params[:file].read
        else
          params[:content].to_s
        end
      end

      def authorize_for_import(student)
        return true if current_user.admin?

        current_user.personal? && student.trainer_id == current_user.trainer_id
      end

      def render_import_error(message)
        render json: { error: message }, status: :unprocessable_content
      end

      def import_params
        params.permit(:file, :content, :student_id, :filename)
      end
    end
  end
end
