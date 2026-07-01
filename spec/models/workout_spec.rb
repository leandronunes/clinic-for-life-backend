require "rails_helper"

RSpec.describe Workout, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to have_many(:exercises).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:workout) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Workout::STATUSES) }

    it "does not allow two active workouts at the same position for the same student" do
      student = create(:student)
      create(:workout, student: student, status: "active", position: 1)
      duplicate = build(:workout, student: student, status: "active", position: 1)
      expect(duplicate).not_to be_valid
    end

    it "allows the same position for active and archived workouts of the same student" do
      student = create(:student)
      create(:workout, student: student, status: "active", position: 1)
      coexisting = build(:workout, :archived, student: student, position: 1)
      expect(coexisting).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active workouts" do
      active = create(:workout, status: "active")
      create(:workout, :archived)
      expect(Workout.active).to contain_exactly(active)
    end

    it ".archived returns only archived workouts" do
      archived = create(:workout, :archived)
      create(:workout, status: "active")
      expect(Workout.archived).to contain_exactly(archived)
    end
  end

  describe "#archive!" do
    it "marks the workout as archived with a timestamp" do
      workout = create(:workout, status: "active")
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)
      workout.archive!
      expect(workout.status).to eq("archived")
      expect(workout.archived_at).to be_present
    end

    it "assigns the next available position in the archived group" do
      student = create(:student)
      create(:workout, :archived, student: student, position: 1)
      workout = create(:workout, student: student, status: "active", position: 1)
      workout.archive!
      expect(workout.position).to eq(2)
    end
  end

  describe "#unarchive!" do
    it "marks the workout as active and clears archived_at" do
      workout = create(:workout, :archived)
      workout.unarchive!
      expect(workout.status).to eq("active")
      expect(workout.archived_at).to be_nil
    end

    it "assigns the next available position in the active group" do
      student = create(:student)
      create(:workout, student: student, status: "active", position: 1)
      workout = create(:workout, :archived, student: student, position: 1)
      workout.unarchive!
      expect(workout.position).to eq(2)
    end
  end

  describe "#archived?" do
    it "returns true when status is archived" do
      expect(build(:workout, :archived).archived?).to be true
    end

    it "returns false when status is active" do
      expect(build(:workout, status: "active").archived?).to be false
    end
  end

  describe "ordered exercises association" do
    it "returns exercises ordered by position" do
      workout = create(:workout)
      second = create(:exercise, workout: workout, position: 2)
      first = create(:exercise, workout: workout, position: 1)
      expect(workout.exercises).to eq([ first, second ])
    end
  end
end
