require "rails_helper"

RSpec.describe ExerciseCheckIn do
  it "rejects a duplicate exercise within the same check-in" do
    check_in = create(:workout_check_in)
    exercise = create(:exercise, workout: check_in.workout)
    create(:exercise_check_in, workout_check_in: check_in, exercise: exercise)

    duplicate = build(:exercise_check_in, workout_check_in: check_in, exercise: exercise)

    expect(duplicate).not_to be_valid
  end

  it "allows the same exercise across different check-ins" do
    workout = create(:workout)
    exercise = create(:exercise, workout: workout)
    first_check_in = create(:workout_check_in, :completed, workout: workout)
    second_check_in = create(:workout_check_in, workout: workout)
    create(:exercise_check_in, workout_check_in: first_check_in, exercise: exercise)

    expect(build(:exercise_check_in, workout_check_in: second_check_in, exercise: exercise)).to be_valid
  end
end
