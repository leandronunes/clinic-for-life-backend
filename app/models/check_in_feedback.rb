class CheckInFeedback < ApplicationRecord
  belongs_to :workout_check_in
  belongs_to :author, class_name: "User", optional: true

  validates :emoji, presence: true, if: -> { message.blank? }
  validates :message, presence: true, if: -> { emoji.blank? }
end
