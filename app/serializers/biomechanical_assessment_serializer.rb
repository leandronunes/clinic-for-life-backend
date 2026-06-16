class BiomechanicalAssessmentSerializer
  def initialize(assessment)
    @assessment = assessment
  end

  def as_json(*)
    {
      id: @assessment.id.to_s,
      created_at: @assessment.created_at&.iso8601,
      images: @assessment.images_map
    }
  end
end
