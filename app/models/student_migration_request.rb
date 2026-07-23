class StudentMigrationRequest < ApplicationRecord
  STATUSES = %w[pending accepted rejected].freeze

  belongs_to :student
  belongs_to :requested_by, class_name: "User"
  belongs_to :source_organization, class_name: "Organization"
  belongs_to :target_organization, class_name: "Organization"

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :organizations_differ

  scope :pending, -> { where(status: "pending") }

  STATUSES.each do |status_name|
    define_method("#{status_name}?") { status == status_name }
  end

  private

  def organizations_differ
    return if source_organization_id != target_organization_id

    errors.add(:target_organization_id, "deve ser diferente da organização atual do aluno")
  end
end
