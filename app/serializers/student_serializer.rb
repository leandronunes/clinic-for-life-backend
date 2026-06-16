class StudentSerializer
  def initialize(student)
    @student = student
  end

  def as_json(*)
    {
      id: @student.id.to_s,
      name: @student.name,
      birth_date: @student.birth_date&.iso8601,
      sex: @student.sex,
      height_cm: @student.height_cm,
      email: @student.email,
      phone: @student.phone,
      trainer_id: @student.trainer_id&.to_s,
      trainer_name: @student.trainer_name,
      status: @student.status,
      health_plan: @student.health_plan,
      emergency_contact: @student.emergency_contact,
      created_at: @student.created_at&.iso8601
    }
  end
end
