class SchedulePlanSlot < ApplicationRecord
  WEEKDAYS = (0..6).freeze
  TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  belongs_to :schedule_plan

  validates :weekday, presence: true, inclusion: { in: WEEKDAYS }, uniqueness: { scope: :schedule_plan_id }
  validates :time, presence: true, format: { with: TIME_FORMAT, message: "deve estar no formato HH:mm" }
  validates :duration_minutes, presence: true, numericality: { only_integer: true, in: 15..240 }
end
