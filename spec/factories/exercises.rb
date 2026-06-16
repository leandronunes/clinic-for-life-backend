FactoryBot.define do
  factory :exercise do
    association :workout
    sequence(:name) { |n| "Exercise #{n}" }
    sets { 3 }
    reps { "10-12" }
    load_kg { 20.0 }
    rest_seconds { 60 }
    muscle_group { "Chest" }
    video_url { "https://www.youtube.com/embed/abc" }
    position { 1 }
  end
end
