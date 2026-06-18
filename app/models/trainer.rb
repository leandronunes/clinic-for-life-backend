class Trainer < ApplicationRecord
  STATUSES = %w[active blocked inactive].freeze

  has_many :students, dependent: :nullify
  has_one :user, dependent: :nullify

  validates :name, presence: true
  validates :cpf, uniqueness: true, allow_blank: true
  validates :cref, uniqueness: true, allow_blank: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true, inclusion: { in: STATUSES }

  before_validation { self.email = email.to_s.downcase.strip }

  def students_count
    students.count
  end
end
