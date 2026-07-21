# Throttle abusive requests to protect health data endpoints.
class Rack::Attack
  # Allow local development tooling to bypass throttling.
  safelist("allow-localhost") do |req|
    [ "127.0.0.1", "::1" ].include?(req.ip)
  end

  # General throttle: 300 requests per 5 minutes per IP.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Stricter throttle on login attempts: 10 per minute per IP.
  throttle("logins/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end

  # Stricter throttle on password reset requests: 5 per minute per IP —
  # each hit sends an e-mail, so this also caps how fast an attacker can
  # spam a victim's inbox.
  throttle("password_reset/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/auth/password/forgot" && req.post?
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  end
end
