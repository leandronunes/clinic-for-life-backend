class Student < ApplicationRecord
  SEXES = %w[female male other].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :trainer, optional: true
  has_one :user, dependent: :nullify
  has_many :bioimpedance_measurements, dependent: :destroy
  has_many :evolution_photos, dependent: :destroy
  has_many :biomechanical_assessments, dependent: :destroy
  has_one :structural_assessment, dependent: :destroy
  has_one :anamnesis, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :exams, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :sex, presence: true, inclusion: { in: SEXES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :height_cm, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true

  before_validation { self.email = email.to_s.downcase.strip }

  def trainer_name
    trainer&.name
  end
end
