require "rails_helper"

RSpec.describe CheckInFeedback do
  it "is valid with a message only" do
    expect(build(:check_in_feedback, message: "Bom treino!", emoji: nil)).to be_valid
  end

  it "is valid with an emoji only" do
    expect(build(:check_in_feedback, :with_emoji)).to be_valid
  end

  it "is valid with both emoji and message" do
    expect(build(:check_in_feedback, :with_message_and_emoji)).to be_valid
  end

  it "is invalid without either emoji or message" do
    expect(build(:check_in_feedback, message: nil, emoji: nil)).not_to be_valid
  end

  it "survives its author being deleted" do
    feedback = create(:check_in_feedback)
    feedback.author.destroy!
    expect(feedback.reload.author_id).to be_nil
  end
end
