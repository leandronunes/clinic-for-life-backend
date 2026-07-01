class Workout < ApplicationRecord
  STATUSES = %w[active archived].freeze

  belongs_to :student
  has_many :exercises, -> { order(:position, :id) }, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :position, numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: %i[student_id status] }

  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }

  def archived?
    status == "archived"
  end

  def archive!
    new_pos = student.workouts.archived.maximum(:position).to_i + 1
    update!(status: "archived", archived_at: Time.current, position: new_pos)
  end

  def unarchive!
    new_pos = student.workouts.active.maximum(:position).to_i + 1
    update!(status: "active", archived_at: nil, position: new_pos)
  end
end
