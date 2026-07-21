class ChatMessage < ApplicationRecord
  SENDER_ROLES = %w[personal aluno].freeze
  MAX_BODY_LENGTH = 4000

  belongs_to :student
  belongs_to :sender, class_name: "User", foreign_key: :sender_id

  validates :sender_role, presence: true, inclusion: { in: SENDER_ROLES }
  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }

  before_validation { self.body = body.to_s.strip }

  # Mensagens não lidas do ponto de vista de quem tem o papel oposto a
  # `role` — nunca conta as que o próprio usuário enviou.
  scope :unread_for, ->(role) { where(read_at: nil).where.not(sender_role: role) }
end
