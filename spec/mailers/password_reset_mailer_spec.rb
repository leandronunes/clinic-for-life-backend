require "rails_helper"

RSpec.describe PasswordResetMailer, type: :mailer do
  describe "#reset_instructions" do
    let(:user) { create(:user, email: "reset@forlife.app", name: "Júlia Ferreira") }
    let(:mail) { PasswordResetMailer.reset_instructions(user, "raw-token-xyz") }

    it "renders the subject in pt-br" do
      expect(mail.subject).to eq("Redefinição de senha — Núcleo For Life")
    end

    it "sends to the user's e-mail" do
      expect(mail.to).to eq([ "reset@forlife.app" ])
    end

    it "includes the reset link with the raw token in both parts" do
      reset_url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:5173")}/redefinir-senha?token=raw-token-xyz"

      expect(mail.html_part.body.to_s).to include(reset_url)
      expect(mail.text_part.body.to_s).to include(reset_url)
    end

    it "greets the user by name" do
      expect(mail.html_part.body.to_s).to include("Júlia Ferreira")
    end
  end
end
