FactoryBot.define do
  factory :biomechanical_image do
    association :biomechanical_assessment
    slot { "frontal" }
    image_url { "https://example.com/frontal.jpg" }
  end
end
