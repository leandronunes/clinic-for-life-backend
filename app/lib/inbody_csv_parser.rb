require "csv"
require "bigdecimal"

# Parses the CSV format exported by InBody body composition devices.
#
# The file has Portuguese headers with units in parentheses, e.g.:
#   data,Equipamento de medição,Peso(kg),Massa Muscular(kg),...
#   20260602173120,H30,91.6,36.8,...
#
# - "data" column holds a 14-digit timestamp: YYYYMMDDHHMMSS
# - Missing/not-measured values are represented as "-"
class InbodyCsvParser
  SIGNATURE_COLUMNS = %w[data Peso(kg)].freeze

  ParsedRow = Struct.new(
    :measured_on, :weight_kg, :muscle_mass_kg,
    :fat_percentage, :bmi, :visceral_fat,
    keyword_init: true
  )

  def self.inbody_format?(headers)
    SIGNATURE_COLUMNS.all? { |c| headers.include?(c) }
  end

  # Returns an array of ParsedRow, or nil if the CSV is malformed.
  def self.parse(raw_content)
    # params[:file].read returns ASCII-8BIT (binary). We must force_encoding first
    # so Ruby treats the bytes as UTF-8 instead of re-encoding byte-by-byte, which
    # would corrupt multi-byte characters like "²" (IMC column) or "í" (Nível).
    content = strip_bom(raw_content.dup.force_encoding("UTF-8"))
    table   = CSV.parse(content, headers: true)

    return nil unless inbody_format?(table.headers.map(&:to_s))

    table.filter_map { |row| parse_row(row) }
  rescue CSV::MalformedCSVError
    nil
  end

  private_class_method def self.strip_bom(str)
    str.sub("\xEF\xBB\xBF", "")
  end

  private_class_method def self.parse_row(row)
    date   = parse_date(row["data"])
    weight = parse_decimal(row["Peso(kg)"])

    # Skip rows that are missing the two mandatory fields.
    return nil unless date && weight

    ParsedRow.new(
      measured_on:    date,
      weight_kg:      weight,
      muscle_mass_kg: parse_decimal(row["Massa Muscular(kg)"]),
      fat_percentage: parse_decimal(row["Gordura Corporal(%)"]),
      bmi:            parse_decimal(row["IMC(kg/m²)"]),
      # Prefer the dimensionless level; fall back to visceral area in cm².
      visceral_fat:   parse_decimal(row["Nível de Gordura Visceral(Level)"]) ||
                      parse_decimal(row["Área de gordura visceral(cm²)"])
    )
  end

  # Timestamp format: YYYYMMDDHHMMSS (14 chars) — only the date portion is used.
  private_class_method def self.parse_date(value)
    str = value.to_s.strip
    return nil if str.blank? || str == "-" || str.length < 8

    Date.new(str[0, 4].to_i, str[4, 2].to_i, str[6, 2].to_i)
  rescue ArgumentError
    nil
  end

  private_class_method def self.parse_decimal(value)
    str = value.to_s.strip
    return nil if str.blank? || str == "-"

    BigDecimal(str)
  rescue ArgumentError
    nil
  end
end
