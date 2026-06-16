class ExternalProfessional < ApplicationRecord
  belongs_to :anamnesis

  validates :name, presence: true
end
