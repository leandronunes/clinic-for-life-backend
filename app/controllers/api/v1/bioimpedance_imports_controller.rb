require "csv"

module Api
  module V1
    # Handles CSV bulk import of bioimpedance measurements.
    # Expected headers: student_email, measured_on, weight_kg, muscle_mass_kg,
    #                   fat_percentage, visceral_fat, bmi
    class BioimpedanceImportsController < BaseController
      before_action :require_write_access!

      REQUIRED_HEADERS = %w[student_email measured_on weight_kg].freeze

      # POST /api/v1/bioimpedance/import
      def create
        content = read_payload
        return render_error("File is required") if content.blank?

        rows = parse_csv(content)
        return render_error("Invalid CSV: missing required headers") if rows.nil?

        result = import_rows(rows)
        import = BioimpedanceImport.create!(
          trainer_id: current_user.trainer_id,
          filename: params[:filename].presence || "import.csv",
          total_rows: rows.size,
          imported_count: result[:imported],
          errors_log: result[:errors]
        )
        audit!("bioimpedance.import", record: import,
               metadata: { imported: result[:imported], failed: result[:errors].size })

        render_data({
          total_rows: rows.size,
          imported_count: result[:imported],
          errors: result[:errors]
        }, status: :created)
      end

      private

      def read_payload
        if params[:file].respond_to?(:read)
          params[:file].read
        else
          params[:content].to_s
        end
      end

      def parse_csv(content)
        table = CSV.parse(content, headers: true)
        headers = table.headers.compact.map { |h| h.to_s.strip }
        return nil unless REQUIRED_HEADERS.all? { |h| headers.include?(h) }

        table
      rescue CSV::MalformedCSVError
        nil
      end

      def import_rows(rows)
        imported = 0
        errors = []

        rows.each_with_index do |row, index|
          student = Student.find_by("lower(email) = ?", row["student_email"].to_s.downcase.strip)
          unless student
            errors << { row: index + 2, error: "Student not found: #{row['student_email']}" }
            next
          end
          unless authorize_for_import(student)
            errors << { row: index + 2, error: "Not authorized for this student" }
            next
          end

          measurement = student.bioimpedance_measurements.new(
            measured_on: row["measured_on"],
            weight_kg: row["weight_kg"],
            muscle_mass_kg: row["muscle_mass_kg"],
            fat_percentage: row["fat_percentage"],
            visceral_fat: row["visceral_fat"],
            bmi: row["bmi"].presence,
            source: "import"
          )

          if measurement.save
            imported += 1
          else
            errors << { row: index + 2, error: measurement.errors.full_messages.join(", ") }
          end
        end

        { imported: imported, errors: errors }
      end

      def authorize_for_import(student)
        return true if current_user.admin?

        current_user.personal? && student.trainer_id == current_user.trainer_id
      end

      def render_error(message)
        render json: { error: message }, status: :unprocessable_entity
      end
    end
  end
end
