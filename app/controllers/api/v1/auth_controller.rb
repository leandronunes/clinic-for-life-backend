module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_request!, only: :login

      # POST /api/v1/auth/login
      def login
        user = User.find_by("lower(email) = ?", params[:email].to_s.downcase.strip)

        if user&.authenticate(params[:password])
          user.update_column(:last_login_at, Time.current)
          audit!("user.login", record: user)
          render_data(session_payload(user))
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      # GET /api/v1/auth/me
      def me
        render_data(UserSerializer.new(current_user).as_json)
      end

      private

      def session_payload(user)
        token = JsonWebToken.encode({ sub: user.id, email: user.email, role: user.role })
        {
          token: token,
          user: UserSerializer.new(user).as_json,
          expires_at: JsonWebToken::DEFAULT_EXP.from_now.iso8601
        }
      end
    end
  end
end
