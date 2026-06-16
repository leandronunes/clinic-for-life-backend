FactoryBot.define do
  factory :exam do
    association :student
    sequence(:name) { |n| "Exam #{n}" }
    description { "Blood test" }
    file_url { "https://example.com/exam.pdf" }
    content_type { "application/pdf" }
    size { 12_345 }
    uploaded_at { Time.current }
  end
end
