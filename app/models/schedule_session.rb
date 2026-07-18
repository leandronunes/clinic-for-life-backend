class ScheduleSession < ApplicationRecord
  STATUSES = %w[planned done missed canceled].freeze

  belongs_to :student
  belongs_to :trainer
  belongs_to :schedule_plan, optional: true
  belongs_to :workout, optional: true

  validates :starts_at, presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, in: 15..240 }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
