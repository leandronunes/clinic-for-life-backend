FactoryBot.define do
  factory :evolution_photo do
    association :student
    sequence(:taken_on) { |n| Date.new(2025, 1, 1) + n.months }
    image_url { "https://example.com/photo.jpg" }
    weight_kg { 70.0 }
    fat_percentage { 25.0 }
    muscle_mass_kg { 30.0 }
  end
end
