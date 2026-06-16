FactoryBot.define do
  factory :bioimpedance_import do
    association :trainer
    filename { "import.csv" }
    total_rows { 0 }
    imported_count { 0 }
    errors_log { [] }
  end
end
