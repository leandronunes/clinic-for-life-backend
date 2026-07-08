require "rails_helper"

RSpec.describe Exercise, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workout) }
  end

  describe "validations" do
    subject { build(:exercise) }

    it { is_expected.to validate_presence_of(:name) }

    it "requires a positive number of sets" do
      expect(build(:exercise, sets: 0)).not_to be_valid
    end

    it "rejects negative rest seconds" do
      expect(build(:exercise, rest_seconds: -5)).not_to be_valid
    end

    it "allows zero rest seconds" do
      expect(build(:exercise, rest_seconds: 0)).to be_valid
    end
  end

  describe "kind" do
    it "defaults to strength for legacy records" do
      exercise = Exercise.new(workout: build(:workout), name: "Legacy", muscle_group: "Chest",
                               reps: "10")
      expect(exercise.kind).to eq("strength")
    end

    it "rejects an invalid kind" do
      expect(build(:exercise, kind: "yoga")).not_to be_valid
    end

    it "is valid for cardio" do
      expect(build(:exercise, :cardio)).to be_valid
    end

    it "is valid for mobility" do
      expect(build(:exercise, :mobility)).to be_valid
    end
  end

  describe "cardio-specific validation" do
    it "requires duration or distance" do
      exercise = build(:exercise, :cardio, duration_seconds: nil, distance_value: nil)
      expect(exercise).not_to be_valid
      expect(exercise.errors[:base]).to be_present
    end

    it "is valid with only duration" do
      expect(build(:exercise, :cardio, distance_value: nil, duration_seconds: 600)).to be_valid
    end

    it "is valid with only distance" do
      expect(build(:exercise, :cardio, duration_seconds: nil, distance_value: 3)).to be_valid
    end

    it "rejects an invalid distance_unit" do
      expect(build(:exercise, :cardio, distance_unit: "miles")).not_to be_valid
    end

    it "rejects an out-of-range hr_zone" do
      expect(build(:exercise, :cardio, hr_zone: 6)).not_to be_valid
    end
  end

  describe "reps requirement" do
    it "requires reps for strength" do
      expect(build(:exercise, reps: nil)).not_to be_valid
    end

    it "requires reps for mobility" do
      expect(build(:exercise, :mobility, reps: nil)).not_to be_valid
    end

    it "does not require reps for cardio" do
      expect(build(:exercise, :cardio, reps: nil)).to be_valid
    end
  end

  describe "muscle_group requirement" do
    it "requires muscle_group for strength" do
      expect(build(:exercise, muscle_group: nil)).not_to be_valid
    end

    it "does not require muscle_group for mobility" do
      expect(build(:exercise, :mobility, muscle_group: nil)).to be_valid
    end

    it "does not require muscle_group for cardio" do
      expect(build(:exercise, :cardio, muscle_group: nil)).to be_valid
    end
  end
end
