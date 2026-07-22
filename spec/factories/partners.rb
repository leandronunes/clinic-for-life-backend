FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partner #{n}" }
    category { "Nutrition" }
    description { "A great partner." }
    discount_details { "10% off on the first visit." }
    coupon { "FORLIFE10" }
    link { "https://example.com/partner" }
    logo_url { "https://example.com/logo.png" }
    association :organization
  end
end
