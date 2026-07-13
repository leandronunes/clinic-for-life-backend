require "csv"

module Api
  module V1
    # Handles CSV/PDF import of bioimpedance measurements exported by InBody devices
    # (raw CSV export, or a PDF report from the mynutri platform).
    # The student is identified by the student_id param — neither file has patient info
    # reliable enough to match against our records.
    class BioimpedanceImportsController < BaseController
      before_action :require_write_access!

      # POST /api/v1/bioimpedance/import
      def create
        content = read_payload
        return render_import_error("File is required") if content.blank?

        student = Student.find_by(id: import_params[:student_id])
        return render_import_error("Aluno não encontrado") unless student
        return render json: { error: "Forbidden" }, status: :forbidden unless authorize_for_import(student)

        rows = parse_content(content)
        return render_import_error("Formato de arquivo inválido ou não reconhecido como InBody") if rows.nil?
        return render_import_error("Nenhuma linha válida encontrada no arquivo") if rows.empty?

        result = persist_rows(student, rows)

        BioimpedanceImport.create!(
          trainer_id:     current_user.trainer_id,
          filename:       import_params[:filename].presence || default_filename(content),
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

      def parse_content(content)
        if MynutriPdfParser.pdf_format?(content)
          MynutriPdfParser.parse(content)
        else
          InbodyCsvParser.parse(content)
        end
      end

      def default_filename(content)
        MynutriPdfParser.pdf_format?(content) ? "import.pdf" : "import.csv"
      end

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
