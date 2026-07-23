class User < ApplicationRecord
  has_secure_password

  ROLES = %w[admin personal student].freeze
  RESET_TOKEN_EXPIRY = 30.minutes

  belongs_to :trainer, optional: true
  belongs_to :student, optional: true
  belongs_to :organization
  has_many :audit_logs, dependent: :nullify
  has_many :push_subscriptions, dependent: :destroy
  has_many :authored_feedbacks, class_name: "CheckInFeedback", foreign_key: :author_id, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
  validate :password_strength, if: -> { password.present? }

  before_validation { self.email = email.to_s.downcase.strip }
  before_validation :ensure_admin_has_trainer, if: -> { admin? && trainer.blank? }

  ROLES.each do |role_name|
    define_method("#{role_name}?") { role == role_name }
  end

  # Looks up a user by a raw password-reset token (as received from the
  # reset link), rejecting it if it's unknown or older than
  # RESET_TOKEN_EXPIRY. Only the digest is ever persisted (see
  # #generate_password_reset_token!), so lookup hashes the raw token the
  # same way before querying.
  def self.find_by_valid_reset_token(raw_token)
    return nil if raw_token.blank?

    user = find_by(reset_password_token_digest: Digest::SHA256.hexdigest(raw_token))
    return nil if user.nil?
    return nil if user.reset_password_sent_at.nil?
    return nil if user.reset_password_sent_at < RESET_TOKEN_EXPIRY.ago

    user
  end

  # Generates a fresh raw token, persists only its digest, and returns the
  # raw token so the caller can e-mail it — it is never stored or logged.
  # Overwrites any previous token (so requesting a new link invalidates
  # earlier ones).
  def generate_password_reset_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(reset_password_token_digest: Digest::SHA256.hexdigest(raw_token), reset_password_sent_at: Time.current)
    raw_token
  end

  def clear_password_reset_token!
    update!(reset_password_token_digest: nil, reset_password_sent_at: nil)
  end

  # Which side of a 1:1 chat this user represents. Admins act as staff here
  # too — same as everywhere else they can view/act on behalf of a personal.
  def chat_role
    student? ? "aluno" : "personal"
  end

  private

  # Admin is a strict superset of personal throughout this app (see
  # AuthController's founder-admin comment) — every admin needs a real Trainer
  # row to be usable anywhere a personal already can be (e.g. as a student's
  # trainer_id after an org-migration request is accepted). Founder-admins
  # already arrive with trainer assigned before this runs; this only fills the
  # gap for admins created some other way (seeds, future admin-invite flows).
  def ensure_admin_has_trainer
    self.trainer = Trainer.find_by("lower(email) = ?", email) ||
                    Trainer.new(name: name, email: email, organization: organization,
                                status: "active", approved_at: Time.current)
  end

  # Strong password policy: min 8 chars, upper, lower, digit and special char.
  def password_strength
    errors.add(:password, "must be at least 8 characters") if password.length < 8
    errors.add(:password, "must include an uppercase letter") unless password.match?(/[A-Z]/)
    errors.add(:password, "must include a lowercase letter") unless password.match?(/[a-z]/)
    errors.add(:password, "must include a number") unless password.match?(/\d/)
    errors.add(:password, "must include a special character") unless password.match?(/[^A-Za-z0-9]/)
  end
end
