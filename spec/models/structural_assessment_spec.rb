require "rails_helper"

RSpec.describe StructuralAssessment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  it "exposes all 13 boolean item names" do
    expect(StructuralAssessment::ITEMS.size).to eq(13)
    expect(StructuralAssessment::ITEMS).to include("scoliosis", "knee_valgus", "flat_foot_arch")
  end

  it "defaults all findings to false" do
    assessment = create(:structural_assessment)
    StructuralAssessment::ITEMS.each do |item|
      expect(assessment.public_send(item)).to be(false)
    end
  end
end
