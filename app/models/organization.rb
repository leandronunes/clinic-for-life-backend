class Organization < ApplicationRecord
  DOMAIN_FORMAT = /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/

  has_many :users, dependent: :nullify
  has_many :trainers, dependent: :nullify
  has_many :students, dependent: :nullify
  has_many :partners, dependent: :nullify

  validates :name, presence: true
  validates :domain, presence: true, uniqueness: { case_sensitive: false },
                      format: { with: DOMAIN_FORMAT }

  before_validation { self.domain = domain.to_s.downcase.strip }
end
