class Organization < ApplicationRecord
  # Aceita tanto um slug simples ("acme-clinic", usado no autoatendimento de
  # cadastro) quanto um hostname completo com múltiplos rótulos
  # ("acme.clinicforlife.com.br") — a vitrine pública de parceiros casa
  # esse campo contra o host acessado pelo visitante (ver
  # Api::V1::PartnersController#public_partner_scope).
  DOMAIN_LABEL = /[a-z0-9]([a-z0-9-]*[a-z0-9])?/
  DOMAIN_FORMAT = /\A#{DOMAIN_LABEL}(\.#{DOMAIN_LABEL})*\z/

  has_many :users, dependent: :nullify
  has_many :trainers, dependent: :nullify
  has_many :students, dependent: :nullify
  has_many :partners, dependent: :nullify

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: { case_sensitive: false },
                      format: { with: DOMAIN_FORMAT }

  before_validation { self.domain = domain.to_s.downcase.strip }
end
