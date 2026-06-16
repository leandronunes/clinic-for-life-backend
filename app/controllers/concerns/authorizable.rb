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

  # Trainers may only reach students from their own portfolio; admins see all;
  # students may only reach their own record.
  def authorize_student!(student)
    return if current_user&.admin?
    return if current_user&.personal? && student.trainer_id == current_user.trainer_id
    return if current_user&.student? && student.id == current_user.student_id

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
