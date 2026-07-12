class ExerciseCheckIn < ApplicationRecord
  belongs_to :workout_check_in
  belongs_to :exercise

  validates :exercise_id, uniqueness: { scope: :workout_check_in_id }
end
