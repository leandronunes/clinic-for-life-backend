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
