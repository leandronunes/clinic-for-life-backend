require "rails_helper"

RSpec.describe Trainer, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:students).dependent(:nullify) }
    it { is_expected.to have_one(:user).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:trainer) }

    it { is_expected.to validate_presence_of(:name) }
    

    it "enforces cpf uniqueness" do
      existing = create(:trainer)
      expect(build(:trainer, cpf: existing.cpf)).not_to be_valid
    end

    
    it { is_expected.to validate_uniqueness_of(:cref) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_inclusion_of(:status).in_array(Trainer::STATUSES) }

    it "rejects malformed emails" do
      expect(build(:trainer, email: "not-an-email")).not_to be_valid
    end
  end

  describe "email normalization" do
    it "downcases and strips the email" do
      trainer = create(:trainer, email: " Rafael@Forlife.APP ")
      expect(trainer.email).to eq("rafael@forlife.app")
    end
  end

  describe "#students_count" do
    it "counts associated students" do
      trainer = create(:trainer)
      create_list(:student, 2, trainer: trainer)
      expect(trainer.students_count).to eq(2)
    end

    it "is zero with no students" do
      expect(create(:trainer).students_count).to eq(0)
    end
  end
end
