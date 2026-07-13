class Feedback < ApplicationRecord
  KINDS = %w[elogio correcao incentivo].freeze

  belongs_to :student
  belongs_to :workout_check_in
  belongs_to :author, class_name: "User", optional: true

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :message, presence: true, length: { maximum: 500 }
end
