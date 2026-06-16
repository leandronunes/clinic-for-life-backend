module Auditable
  extend ActiveSupport::Concern

  # Records an immutable audit trail entry for sensitive operations.
  def audit!(action, record: nil, justification: nil, metadata: {})
    AuditLog.create!(
      user: current_user,
      action: action,
      auditable_type: record&.class&.name,
      auditable_id: record&.id,
      ip_address: request.remote_ip,
      justification: justification,
      metadata: metadata
    )
  end
end
