require "rails_helper"

RSpec.describe Student, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:trainer).optional }
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_one(:user).dependent(:nullify) }
    it { is_expected.to have_many(:bioimpedance_measurements).dependent(:destroy) }
    it { is_expected.to have_many(:evolution_photos).dependent(:destroy) }
    it { is_expected.to have_many(:biomechanical_assessments).dependent(:destroy) }
    it { is_expected.to have_one(:structural_assessment).dependent(:destroy) }
    it { is_expected.to have_one(:anamnesis).dependent(:destroy) }
    it { is_expected.to have_many(:workouts).dependent(:destroy) }
    it { is_expected.to have_many(:exams).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:student) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_inclusion_of(:sex).in_array(Student::SEXES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Student::STATUSES) }

    it "allows a nil contracted_workouts_per_cycle" do
      expect(build(:student, contracted_workouts_per_cycle: nil)).to be_valid
    end

    it "rejects a zero or negative contracted_workouts_per_cycle" do
      expect(build(:student, contracted_workouts_per_cycle: 0)).not_to be_valid
      expect(build(:student, contracted_workouts_per_cycle: -1)).not_to be_valid
    end

    it "rejects a non-integer contracted_workouts_per_cycle" do
      expect(build(:student, contracted_workouts_per_cycle: 1.5)).not_to be_valid
    end
  end

  describe "email normalization" do
    it "downcases and strips the email" do
      student = create(:student, email: " Julia@Email.COM ")
      expect(student.email).to eq("julia@email.com")
    end
  end

  describe "#trainer_name" do
    it "returns the associated trainer name" do
      trainer = create(:trainer, name: "Beatriz Lima")
      expect(create(:student, trainer: trainer).trainer_name).to eq("Beatriz Lima")
    end

    it "returns nil with no trainer" do
      expect(build(:student, trainer: nil).trainer_name).to be_nil
    end
  end

  describe "organization/trainer consistency" do
    it "is valid when the student's organization matches the trainer's" do
      trainer = create(:trainer)
      expect(build(:student, trainer: trainer, organization: trainer.organization)).to be_valid
    end

    it "is invalid when the student's organization differs from the trainer's" do
      trainer = create(:trainer)
      other_org = create(:organization)
      student = build(:student, trainer: trainer, organization: other_org)

      expect(student).not_to be_valid
      expect(student.errors[:organization_id]).to be_present
    end

    it "is valid with any organization when the student has no trainer" do
      expect(build(:student, trainer: nil, organization: create(:organization))).to be_valid
    end
  end
end
