FactoryBot.define do
  factory :workout do
    association :student
    sequence(:title) { |n| "Workout #{n}" }
    focus { "Push" }
    status { "active" }
    position { 1 }
    trainer_name { "Rafael Monteiro" }

    trait :archived do
      status { "archived" }
      archived_at { Time.current }
    end
  end
end
