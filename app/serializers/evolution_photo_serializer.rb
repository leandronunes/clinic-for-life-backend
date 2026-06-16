class EvolutionPhotoSerializer
  def initialize(photo)
    @photo = photo
  end

  def as_json(*)
    {
      id: @photo.id.to_s,
      taken_on: @photo.taken_on&.iso8601,
      image_url: @photo.image_url,
      weight_kg: @photo.weight_kg&.to_f,
      fat_percentage: @photo.fat_percentage&.to_f,
      muscle_mass_kg: @photo.muscle_mass_kg&.to_f
    }
  end
end
