class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, title:, body:, url: nil)
    user = User.find_by(id: user_id)
    return if user.blank?

    PushNotifier.send_to_user(user, title: title, body: body, url: url)
  end
end
