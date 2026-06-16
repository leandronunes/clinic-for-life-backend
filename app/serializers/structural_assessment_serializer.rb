class StructuralAssessmentSerializer
  def initialize(assessment)
    @assessment = assessment
  end

  def as_json(*)
    StructuralAssessment::ITEMS.index_with { |item| @assessment.public_send(item) }
  end
end
