FactoryBot.define do
  factory :exercise do
    association :workout
    kind { "strength" }
    sequence(:name) { |n| "Exercise #{n}" }
    sets { 3 }
    reps { "10-12" }
    load_kg { 20.0 }
    rest_seconds { 60 }
    muscle_group { "Chest" }
    video_url { "https://www.youtube.com/embed/abc" }
    position { 1 }

    trait :cardio do
      kind { "cardio" }
      reps { nil }
      muscle_group { nil }
      load_kg { nil }
      duration_seconds { 1200 }
      distance_value { 5 }
      distance_unit { "km" }
      hr_zone { 2 }
    end

    trait :mobility do
      kind { "mobility" }
      sets { 2 }
      reps { "10" }
      muscle_group { nil }
      load_kg { nil }
    end
  end
end
