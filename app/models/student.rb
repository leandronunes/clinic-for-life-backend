class Student < ApplicationRecord
  SEXES = %w[female male other].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :trainer, optional: true
  belongs_to :organization
  has_one :user, dependent: :nullify
  has_many :bioimpedance_measurements, dependent: :destroy
  has_many :evolution_photos, dependent: :destroy
  has_many :biomechanical_assessments, dependent: :destroy
  has_one :structural_assessment, dependent: :destroy
  has_one :anamnesis, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :exams, dependent: :destroy
  has_many :workout_check_ins, dependent: :destroy
  has_many :attendance_cycles, dependent: :destroy
  has_many :schedule_plans, dependent: :destroy
  has_many :schedule_sessions, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :migration_requests, class_name: "StudentMigrationRequest", dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :sex, presence: true, inclusion: { in: SEXES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :contracted_workouts_per_cycle,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :organization_matches_trainer
  before_validation { self.email = email.to_s.downcase.strip }

  def trainer_name
    trainer&.name
  end

  private

  # student.organization_id não é derivável só via trainer_id (trainer é
  # opcional — aluno pode ficar órfão), por isso é coluna própria; quando
  # há trainer, os dois precisam concordar pra não deixar o aluno "vazar"
  # pra uma organização diferente da do seu próprio personal.
  def organization_matches_trainer
    return if trainer.nil? || organization_id.nil?
    return if organization_id == trainer.organization_id

    errors.add(:organization_id, "deve ser a mesma organização do trainer")
  end
end
