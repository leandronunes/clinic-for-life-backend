require "rails_helper"

RSpec.describe Organization, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:nullify) }
    it { is_expected.to have_many(:trainers).dependent(:nullify) }
    it { is_expected.to have_many(:students).dependent(:nullify) }
    it { is_expected.to have_many(:partners).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_uniqueness_of(:domain).case_insensitive }

    it "accepts a simple lowercase slug" do
      expect(build(:organization, domain: "acme-clinic")).to be_valid
    end

    it "accepts a full hostname with multiple labels" do
      expect(build(:organization, domain: "acme.clinicforlife.com.br")).to be_valid
    end

    it "rejects a domain with uppercase or invalid characters" do
      expect(build(:organization, domain: "Acme Clinic!")).not_to be_valid
    end

    it "rejects a domain starting or ending with a hyphen" do
      expect(build(:organization, domain: "-acme")).not_to be_valid
      expect(build(:organization, domain: "acme-")).not_to be_valid
    end

    it "rejects a hostname with an empty label" do
      expect(build(:organization, domain: "acme..com")).not_to be_valid
      expect(build(:organization, domain: ".acme.com")).not_to be_valid
      expect(build(:organization, domain: "acme.com.")).not_to be_valid
    end
  end

  describe "domain normalization" do
    it "downcases and strips the domain before validation" do
      organization = create(:organization, domain: " Acme-Clinic ")
      expect(organization.domain).to eq("acme-clinic")
    end
  end

  describe "solo" do
    it "defaults to false" do
      expect(create(:organization).solo).to be(false)
    end

    it "can be flagged as a solo trainer's auto-generated organization" do
      expect(create(:organization, :solo).solo).to be(true)
    end
  end
end
