require "rails_helper"

RSpec.describe Feedback do
  it "is invalid with a kind outside KINDS" do
    expect(build(:feedback, kind: "bogus")).not_to be_valid
  end

  it "is invalid without a message" do
    expect(build(:feedback, message: nil)).not_to be_valid
  end

  it "is invalid with a message longer than 500 characters" do
    expect(build(:feedback, message: "a" * 501)).not_to be_valid
  end

  it "survives its author being deleted" do
    feedback = create(:feedback)
    feedback.author.destroy!

    expect(feedback.reload.author_id).to be_nil
  end
end
