class EvolutionPhotoSerializer
  def initialize(photo)
    @photo = photo
  end

  def as_json(*)
    {
      id: @photo.id.to_s,
      measurement_id: @photo.bioimpedance_measurement_id&.to_s,
      taken_on: @photo.taken_on&.iso8601,
      image_url: @photo.image_url
    }
  end
end
