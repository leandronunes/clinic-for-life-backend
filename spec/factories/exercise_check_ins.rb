FactoryBot.define do
  factory :exercise_check_in do
    association :workout_check_in
    association :exercise
    completed_at { Time.current }
  end
end
