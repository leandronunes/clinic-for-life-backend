# Lightweight PORO serializers producing plain hashes for JSON rendering.
class UserSerializer
  def initialize(user)
    @user = user
  end

  def as_json(*)
    {
      id: @user.id.to_s,
      name: @user.name,
      email: @user.email,
      cpf: @user.cpf,
      role: @user.role,
      avatar_url: @user.avatar_url,
      trainer_id: @user.trainer_id&.to_s,
      student_id: @user.student_id&.to_s,
      organization_id: @user.organization_id&.to_s,
      organization_solo: @user.organization.solo,
      mfa_enabled: @user.mfa_enabled,
      pending_approval: @user.trainer.present? && @user.trainer.approved_at.nil?,
      pending_migration_request: pending_migration_request_payload
    }
  end

  private

  # Informational only, unlike pending_approval — a pending migration request
  # never blocks the student's normal access to their current organization
  # (see StudentMigrationRequestsController, no block_if_pending_* gate for it).
  def pending_migration_request_payload
    return nil if @user.student.blank?

    request = @user.student.migration_requests.pending.first
    return nil if request.blank?

    StudentMigrationRequestSerializer.new(request).as_json
  end
end
