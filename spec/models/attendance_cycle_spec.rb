require "rails_helper"

RSpec.describe AttendanceCycle, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  describe "validations" do
    subject { build(:attendance_cycle) }

    it { is_expected.to validate_presence_of(:started_at) }
    it { is_expected.to validate_presence_of(:ended_at) }

    it "rejects a blank contracted_workouts_per_cycle" do
      expect(build(:attendance_cycle, contracted_workouts_per_cycle: nil)).not_to be_valid
    end

    it "rejects a zero or negative contracted_workouts_per_cycle" do
      expect(build(:attendance_cycle, contracted_workouts_per_cycle: 0)).not_to be_valid
    end

    it "rejects an ended_at that is not after started_at" do
      cycle = build(:attendance_cycle, started_at: 1.day.ago, ended_at: 2.days.ago)
      expect(cycle).not_to be_valid
      expect(cycle.errors[:ended_at]).to be_present
    end
  end

  describe "#completed_workouts" do
    it "counts only completed check-ins whose completed_at falls inside the cycle" do
      trainer = create(:trainer)
      student = create(:student, trainer: trainer)
      workout = create(:workout, student: student)
      cycle = create(:attendance_cycle, student: student, started_at: 10.days.ago, ended_at: 2.days.ago)

      create(:workout_check_in, :completed, workout: workout, student: student, completed_at: 5.days.ago)
      create(:workout_check_in, :completed, workout: workout, student: student, completed_at: 4.days.ago)
      # Outside the cycle window
      create(:workout_check_in, :completed, workout: workout, student: student, completed_at: 1.day.ago)
      # In progress, never completed
      create(:workout_check_in, workout: workout, student: student)

      expect(cycle.completed_workouts).to eq(2)
    end
  end
end
