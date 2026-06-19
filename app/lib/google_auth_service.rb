require "net/http"
require "json"

# Verifies a Google OAuth access token and returns the user info hash.
# Extracted into a service so specs can stub it without hitting the network.
class GoogleAuthService
  USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"

  def self.fetch_userinfo(access_token)
    return nil if access_token.blank?

    uri = URI(USERINFO_URL)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |h| h.request(req) }
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError
    nil
  end
end
