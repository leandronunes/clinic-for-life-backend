module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!
    attr_reader :current_user
  end

  private

  def authenticate_request!
    @current_user = user_from_token
    render_unauthorized unless @current_user
  end

  # For actions that work both pre- and post-auth (e.g. the public partners
  # showcase, which shows a narrower org-scoped catalog once logged in) —
  # populates current_user when a valid token is present, without requiring
  # one. Used instead of skip_before_action :authenticate_request! alone,
  # which would leave current_user nil even for an authenticated caller.
  def attempt_authentication!
    @current_user = user_from_token
  end

  def user_from_token
    header = request.headers["Authorization"]
    token = header.to_s.split(" ").last
    return if token.blank?

    payload = JsonWebToken.decode(token)
    return if payload.blank?

    User.find_by(id: payload[:sub])
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
