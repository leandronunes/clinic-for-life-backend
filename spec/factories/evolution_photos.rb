FactoryBot.define do
  factory :evolution_photo do
    association :bioimpedance_measurement
    image_url { "https://example.com/photo.jpg" }

    after(:build) do |photo|
      photo.student ||= photo.bioimpedance_measurement.student
      photo.taken_on ||= photo.bioimpedance_measurement.measured_on
    end
  end
end
