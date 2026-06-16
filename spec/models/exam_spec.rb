require "rails_helper"

RSpec.describe Exam, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  describe "validations" do
    subject { build(:exam) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:file_url) }
  end

  describe "uploaded_at default" do
    it "sets uploaded_at automatically when blank" do
      exam = create(:exam, uploaded_at: nil)
      expect(exam.uploaded_at).to be_present
    end

    it "keeps a provided uploaded_at" do
      timestamp = 2.days.ago.change(usec: 0)
      exam = create(:exam, uploaded_at: timestamp)
      expect(exam.uploaded_at).to be_within(1.second).of(timestamp)
    end
  end
end
