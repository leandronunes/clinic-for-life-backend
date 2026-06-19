module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_request!, only: %i[login register]

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

      # POST /api/v1/auth/register
      # Self-service registration. Associates the new user account with an
      # existing trainer or student record when the e-mail matches one.
      def register
        email = params[:email].to_s.downcase.strip

        if User.exists?(email: email)
          return render json: { error: "E-mail já possui uma conta cadastrada" },
                        status: :unprocessable_entity
        end

        trainer = Trainer.find_by("lower(email) = ?", email)
        student = Student.find_by("lower(email) = ?", email)

        role = trainer.present? ? "personal" : "student"

        user = User.new(
          name: params[:name],
          email: email,
          password: params[:password],
          password_confirmation: params[:password_confirmation],
          role: role,
          trainer: trainer,
          student: student
        )

        if user.save
          audit!("user.register", record: user)
          render_data(session_payload(user), status: :created)
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
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
