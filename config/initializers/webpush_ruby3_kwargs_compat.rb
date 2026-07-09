# The `webpush` gem (0.3.2, the version this app locks to) builds the
# encrypted payload like this:
#
#   def build_payload(message, subscription)
#     encrypt_payload(message, subscription.fetch(:keys))
#   end
#
#   def encrypt_payload(message, p256dh:, auth:)
#     Encryption.encrypt(message, p256dh, auth)
#   end
#
# `subscription.fetch(:keys)` is a Hash passed as a second *positional*
# argument, but `encrypt_payload` declares `p256dh:`/`auth:` as required
# keywords. Ruby < 3.0 implicitly converted a trailing Hash into keywords;
# Ruby 3.0 separated positional and keyword arguments, so on this app's Ruby
# this now raises on every real push send that includes a message body:
#
#   ArgumentError: wrong number of arguments (given 2, expected 1;
#   required keywords: p256dh, auth)
#
# This never surfaces in specs because PushNotifier's tests stub
# Webpush.payload_send rather than exercising Webpush::Request for real.
#
# Patch just the one call site that needs a `**` splat, rather than the gem
# or reimplementing Request ourselves.
#
# Remove this file once a `webpush` release fixes it upstream.
class Webpush::Request
  private

  def build_payload(message, subscription)
    return {} if message.nil? || message.empty?

    encrypt_payload(message, **subscription.fetch(:keys))
  end
end
