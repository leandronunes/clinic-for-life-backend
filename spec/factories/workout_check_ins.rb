FactoryBot.define do
  factory :workout_check_in do
    association :workout
    student { workout.student }
    status { "in_progress" }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end
  end
end
