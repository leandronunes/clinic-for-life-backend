module AuthHelpers
  # Builds an Authorization header with a valid JWT for the given user.
  def auth_headers(user)
    token = JsonWebToken.encode({ sub: user.id, email: user.email, role: user.role })
    { "Authorization" => "Bearer #{token}" }
  end

  # Convenience helpers to issue authenticated JSON requests.
  def json_get(path, user:, params: {})
    get path, params: params, headers: auth_headers(user)
  end

  def json_body
    JSON.parse(response.body)
  end
end
