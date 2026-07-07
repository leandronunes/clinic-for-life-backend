# Bridges Pact provider states to real authentication.
#
# The consumer's pact only records that a Bearer token was present (matched by
# shape, never by value — see src/lib/pact/auth-fixtures.ts on the frontend).
# When the provider verifier replays an interaction it sends that same literal
# placeholder string, which is meaningless to this app. PactStateContext lets a
# `provider_state` setup block declare "verify this interaction as this user",
# and this Rack middleware swaps in a real JWT for that user — minted with the
# exact same JsonWebToken.encode call the real controllers use — before the
# request reaches Rails::Application. Interactions with no context (401
# scenarios) pass the consumer's placeholder header straight through, so the
# real Authenticable#authenticate_request! rejects it exactly as it would in
# production.
module PactStateContext
  @current_user = nil

  class << self
    attr_accessor :current_user

    def as(user)
      self.current_user = user
    end

    def clear
      self.current_user = nil
    end
  end
end

class PactAuthOverride
  def initialize(app)
    @app = app
  end

  def call(env)
    # Single-shot: consume and clear immediately. Interactions with no
    # provider_state at all (e.g. a bare 401 "no token" scenario) never
    # trigger a state-change call, so nothing would otherwise clear a
    # previous interaction's context before this request arrives.
    if (user = PactStateContext.current_user)
      PactStateContext.clear
      token = JsonWebToken.encode({ sub: user.id, email: user.email, role: user.role })
      env["HTTP_AUTHORIZATION"] = "Bearer #{token}"
    end

    @app.call(env)
  end
end
