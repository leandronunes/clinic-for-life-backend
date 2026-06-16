class TrainerSerializer
  def initialize(trainer)
    @trainer = trainer
  end

  def as_json(*)
    {
      id: @trainer.id.to_s,
      name: @trainer.name,
      cpf: @trainer.cpf,
      cref: @trainer.cref,
      email: @trainer.email,
      phone: @trainer.phone,
      status: @trainer.status,
      avatar_url: @trainer.avatar_url,
      students_count: @trainer.students_count
    }
  end
end
