require "rails_helper"

RSpec.describe Anamnesis, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to have_many(:external_professionals).dependent(:destroy) }
  end

  it "exposes the editable field list" do
    expect(Anamnesis::FIELDS).to include("objectives", "medicines", "notes")
  end

  it "destroys dependent external professionals" do
    anamnesis = create(:anamnesis)
    create(:external_professional, anamnesis: anamnesis)
    expect { anamnesis.destroy }.to change(ExternalProfessional, :count).by(-1)
  end
end

RSpec.describe ExternalProfessional, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:anamnesis) }
  end

  describe "validations" do
    subject { build(:external_professional) }

    it { is_expected.to validate_presence_of(:name) }
  end
end
