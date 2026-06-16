FactoryBot.define do
  factory :bioimpedance_measurement do
    association :student
    sequence(:measured_on) { |n| Date.new(2025, 1, 1) + n.days }
    weight_kg { 70.0 }
    muscle_mass_kg { 30.0 }
    fat_percentage { 25.0 }
    visceral_fat { 8.0 }
    source { "InBody" }
  end
end
