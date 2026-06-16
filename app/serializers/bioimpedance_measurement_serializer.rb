class BioimpedanceMeasurementSerializer
  def initialize(measurement)
    @measurement = measurement
  end

  def as_json(*)
    {
      id: @measurement.id.to_s,
      student_id: @measurement.student_id.to_s,
      measured_on: @measurement.measured_on&.iso8601,
      weight_kg: @measurement.weight_kg&.to_f,
      muscle_mass_kg: @measurement.muscle_mass_kg&.to_f,
      fat_percentage: @measurement.fat_percentage&.to_f,
      visceral_fat: @measurement.visceral_fat&.to_f,
      bmi: @measurement.bmi&.to_f,
      source: @measurement.source
    }
  end
end
