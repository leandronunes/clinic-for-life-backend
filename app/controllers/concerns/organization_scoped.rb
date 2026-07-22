# Centraliza o padrão repetido em ~10 controllers (personal só vê o próprio
# trainer_id; aluno só o próprio registro; admin vê tudo) — o branch do
# admin passa a ser "tudo dentro da própria organização", não mais
# "tudo, sem exceção". Extraído pra concern porque esse branch está
# ganhando uma variante security-critical (um site esquecido hoje seria
# inofensivo, com um único tenant; daqui pra frente é vazamento real entre
# organizações) — editar um lugar só é bem mais seguro que confiar em cada
# controller repetir a lógica certa.
module OrganizationScoped
  extend ActiveSupport::Concern

  def current_organization_id
    current_user&.organization_id
  end

  def student_scope
    return Student.where(trainer_id: current_user.trainer_id) if current_user.personal?
    return Student.where(id: current_user.student_id) if current_user.student?

    Student.where(organization_id: current_organization_id)
  end

  def trainer_scope
    return Trainer.where(id: current_user.trainer_id) if current_user.personal?

    Trainer.where(organization_id: current_organization_id)
  end

  def partner_scope
    Partner.where(organization_id: current_organization_id)
  end

  # Pra autorização de um único registro (show/update/destroy) que precisa
  # pertencer à organização de quem está chamando — tipicamente combinado
  # com require_role!(:admin) antes, já que só faz sentido pro branch do
  # admin (personal/aluno já têm seus próprios checks mais específicos).
  def authorize_organization!(record)
    return if record.organization_id == current_organization_id

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
