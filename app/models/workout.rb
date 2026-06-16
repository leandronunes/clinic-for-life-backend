class Workout < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :student
  has_many :exercises, -> { order(:position, :id) }, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }

  def archive!
    update!(status: "archived", archived_at: Time.current)
  end
end
