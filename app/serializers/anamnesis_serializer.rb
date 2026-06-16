class AnamnesisSerializer
  def initialize(anamnesis)
    @anamnesis = anamnesis
  end

  def as_json(*)
    fields = Anamnesis::FIELDS.index_with { |field| @anamnesis.public_send(field) }
    fields.merge(
      id: @anamnesis.id.to_s,
      student_id: @anamnesis.student_id.to_s,
      external_professionals: @anamnesis.external_professionals.map do |professional|
        {
          id: professional.id.to_s,
          name: professional.name,
          specialty: professional.specialty,
          objective: professional.objective
        }
      end
    )
  end
end
