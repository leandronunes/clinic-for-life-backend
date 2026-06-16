FactoryBot.define do
  factory :anamnesis do
    association :student
    objectives { "Lose weight" }
    notes { "No relevant history" }
  end
end
