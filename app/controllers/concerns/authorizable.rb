module Authorizable
  extend ActiveSupport::Concern

  # Ensures the current user holds at least one of the given roles.
  def require_role!(*roles)
    return if current_user && roles.map(&:to_s).include?(current_user.role)

    render json: { error: "Forbidden" }, status: :forbidden
  end

  def require_write_access!
    return if current_user&.admin? || current_user&.personal?

    render json: { error: "Forbidden" }, status: :forbidden
  end

  # Trainers may only reach students from their own portfolio; admins see
  # every student within their own organization; students may only reach
  # their own record.
  def authorize_student!(student)
    return if current_user&.admin? && student.organization_id == current_user.organization_id
    return if current_user&.personal? && student.trainer_id == current_user.trainer_id
    return if current_user&.student? && student.id == current_user.student_id

    render json: { error: "Forbidden" }, status: :forbidden
  end

  # Like authorize_student!, but for staff-only actions (e.g. renewing an
  # attendance cycle) where the student themselves must be excluded even
  # though they're allowed to read/update their own profile elsewhere.
  def authorize_staff_for_student!(student)
    return if current_user&.admin? && student.organization_id == current_user.organization_id
    return if current_user&.personal? && student.trainer_id == current_user.trainer_id

    render json: { error: "Forbidden" }, status: :forbidden
  end

  # A personal whose Trainer#approved_at is still nil requested to join an
  # existing organization and hasn't been approved by that org's admin yet
  # (see TrainersController#approve/#reject). Blocks everything except the
  # handful of self-service account actions explicitly skipped in
  # AuthController — organization_id is already set to the target org at
  # this point, so without this gate a pending trainer would otherwise show
  # up in that org's listings/dashboards despite not being a real member yet.
  def block_if_pending_trainer!
    return unless current_user&.personal?
    return if current_user.trainer&.approved_at.present?

    render json: { error: "Cadastro pendente de aprovação", code: "pending_approval" }, status: :forbidden
  end
end
