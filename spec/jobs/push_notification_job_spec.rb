require "rails_helper"

RSpec.describe PushNotificationJob, type: :job do
  it "calls PushNotifier.send_to_user for the given user" do
    user = create(:user, :student_account)

    expect(PushNotifier).to receive(:send_to_user).with(user, title: "T", body: "B", url: "/x")

    described_class.new.perform(user.id, title: "T", body: "B", url: "/x")
  end

  it "does nothing when the user no longer exists" do
    expect(PushNotifier).not_to receive(:send_to_user)

    described_class.new.perform(-1, title: "T", body: "B")
  end
end
