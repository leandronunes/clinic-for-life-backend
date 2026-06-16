require "jwt"

# Encodes and decodes JWT tokens used for stateless authentication.
class JsonWebToken
  # Sessions expire after 30 days of inactivity (see technical spec).
  DEFAULT_EXP = 30.days

  class << self
    def encode(payload, exp: DEFAULT_EXP.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret)
    end

    def decode(token)
      body = JWT.decode(token, secret).first
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end

    private

    def secret
      ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
    end
  end
end
