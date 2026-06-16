FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Partner #{n}" }
    category { "Nutrition" }
    description { "A great partner." }
    coupon { "FORLIFE10" }
    link { "https://example.com/partner" }
    logo_url { "https://example.com/logo.png" }
  end
end
