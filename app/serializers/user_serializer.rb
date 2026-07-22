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
      role: @user.role,
      avatar_url: @user.avatar_url,
      trainer_id: @user.trainer_id&.to_s,
      student_id: @user.student_id&.to_s,
      mfa_enabled: @user.mfa_enabled,
      pending_approval: @user.trainer.present? && @user.trainer.approved_at.nil?
    }
  end
end
