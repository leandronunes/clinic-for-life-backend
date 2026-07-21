class PasswordResetMailer < ApplicationMailer
  def reset_instructions(user, raw_token)
    @user = user
    @reset_url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:5173")}/redefinir-senha?token=#{raw_token}"

    mail(to: user.email, subject: "Redefinição de senha — Núcleo For Life")
  end
end
