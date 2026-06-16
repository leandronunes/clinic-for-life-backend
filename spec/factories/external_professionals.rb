FactoryBot.define do
  factory :external_professional do
    association :anamnesis
    name { "Dr. Smith" }
    specialty { "Cardiology" }
    objective { "Heart monitoring" }
  end
end
