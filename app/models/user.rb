class User < ApplicationRecord
  has_secure_password

  ROLES = %w[admin personal student].freeze

  belongs_to :trainer, optional: true
  belongs_to :student, optional: true
  has_many :audit_logs, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
  validate :password_strength, if: -> { password.present? }

  before_validation { self.email = email.to_s.downcase.strip }

  ROLES.each do |role_name|
    define_method("#{role_name}?") { role == role_name }
  end

  private

  # Strong password policy: min 8 chars, upper, lower, digit and special char.
  def password_strength
    errors.add(:password, "must be at least 8 characters") if password.length < 8
    errors.add(:password, "must include an uppercase letter") unless password.match?(/[A-Z]/)
    errors.add(:password, "must include a lowercase letter") unless password.match?(/[a-z]/)
    errors.add(:password, "must include a number") unless password.match?(/\d/)
    errors.add(:password, "must include a special character") unless password.match?(/[^A-Za-z0-9]/)
  end
end
