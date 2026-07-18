class SchedulePlan < ApplicationRecord
  # Guarda-corpo contra erro de digitação em ends_on (ex.: ano errado)
  # criando dezenas de milhares de sessões de uma vez.
  MAX_RANGE_DAYS = 366

  belongs_to :student
  belongs_to :trainer
  has_many :schedule_plan_slots, dependent: :destroy
  has_many :schedule_sessions, dependent: :nullify

  validates :starts_on, :ends_on, presence: true
  validates :notes, length: { maximum: 500 }
  validate :ends_on_not_before_starts_on
  validate :range_within_max_days
  validate :has_at_least_one_slot

  private

  def ends_on_not_before_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "deve ser posterior ou igual à data de início") if ends_on < starts_on
  end

  def range_within_max_days
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "o intervalo do plano não pode ultrapassar #{MAX_RANGE_DAYS} dias") if
      (ends_on - starts_on).to_i > MAX_RANGE_DAYS
  end

  def has_at_least_one_slot
    errors.add(:schedule_plan_slots, "selecione pelo menos um dia da semana") if schedule_plan_slots.empty?
  end
end
