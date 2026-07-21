require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to belong_to(:sender).class_name("User").with_foreign_key(:sender_id) }
  end

  describe "validations" do
    subject { build(:chat_message) }

    it { is_expected.to validate_presence_of(:sender_role) }
    it { is_expected.to validate_inclusion_of(:sender_role).in_array(ChatMessage::SENDER_ROLES) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(ChatMessage::MAX_BODY_LENGTH) }

    it "rejects a body that is only whitespace" do
      expect(build(:chat_message, body: "   ")).not_to be_valid
    end
  end

  describe "body normalization" do
    it "strips surrounding whitespace before validation" do
      message = create(:chat_message, body: "  Oi, tudo bem?  ")
      expect(message.body).to eq("Oi, tudo bem?")
    end
  end

  describe ".unread_for" do
    let(:student) { create(:student) }

    it "returns unread messages from the opposite role, never the viewer's own" do
      from_personal = create(:chat_message, :from_personal, student: student)
      from_aluno = create(:chat_message, :from_aluno, student: student)

      expect(student.chat_messages.unread_for("aluno")).to contain_exactly(from_personal)
      expect(student.chat_messages.unread_for("personal")).to contain_exactly(from_aluno)
    end

    it "excludes already-read messages" do
      create(:chat_message, :from_personal, :read, student: student)
      expect(student.chat_messages.unread_for("aluno")).to be_empty
    end
  end
end
