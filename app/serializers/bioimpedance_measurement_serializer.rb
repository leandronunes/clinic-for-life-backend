class BioimpedanceMeasurementSerializer
  def initialize(measurement)
    @measurement = measurement
  end

  def as_json(*)
    photo = @measurement.evolution_photo
    {
      id: @measurement.id.to_s,
      student_id: @measurement.student_id.to_s,
      measured_on: @measurement.measured_on&.iso8601,
      weight_kg: @measurement.weight_kg&.to_f,
      muscle_mass_kg: @measurement.muscle_mass_kg&.to_f,
      fat_percentage: @measurement.fat_percentage&.to_f,
      visceral_fat: @measurement.visceral_fat&.to_f,
      bmi: @measurement.bmi&.to_f,
      source: @measurement.source,
      photo_id: photo&.id&.to_s,
      photo_url: photo&.image_url
    }
  end
end
