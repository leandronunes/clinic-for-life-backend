class PushNotifier
  class << self
    # Best-effort fan-out to every subscription a user has registered. Never
    # raises — this runs inside a background job with no one to surface
    # errors to, so dead subscriptions are pruned and everything else logged.
    def send_to_user(user, title:, body:, url: nil)
      return if user.blank?

      payload = { title: title, body: body, url: url }.compact.to_json

      user.push_subscriptions.find_each do |subscription|
        deliver(subscription, payload)
      end
    end

    private

    def deliver(subscription, payload)
      Webpush.payload_send(
        message: payload,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: ENV.fetch("VAPID_SUBJECT"),
          public_key: ENV.fetch("VAPID_PUBLIC_KEY"),
          private_key: ENV.fetch("VAPID_PRIVATE_KEY")
        }
      )
    rescue Webpush::ExpiredSubscription, Webpush::InvalidSubscription => e
      subscription.destroy
      Rails.logger.info("[PushNotifier] pruned dead subscription id=#{subscription.id}: #{e.message}")
    rescue Webpush::ResponseError => e
      Rails.logger.warn("[PushNotifier] push failed subscription id=#{subscription.id}: #{e.message}")
    rescue StandardError => e
      Rails.logger.error(
        "[PushNotifier] unexpected error subscription id=#{subscription.id}: #{e.class} #{e.message}"
      )
    end
  end
end
