class Feedback < ApplicationRecord
  belongs_to :student
  belongs_to :workout_check_in
  belongs_to :author, class_name: "User", optional: true

  validates :message, presence: true, length: { maximum: 500 }
end
