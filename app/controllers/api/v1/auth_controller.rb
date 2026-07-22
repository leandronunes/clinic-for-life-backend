module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_request!, only: %i[login register google_auth forgot_password reset_password]
      # A pending trainer (awaiting org approval) still needs to manage their
      # own account — see Authorizable#block_if_pending_trainer!.
      skip_before_action :block_if_pending_trainer!, only: %i[me update_me update_password]

      FORGOT_PASSWORD_MESSAGE = "Se o e-mail existir, enviaremos um link de redefinição.".freeze

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
      # existing trainer or student record when the e-mail matches one;
      # otherwise builds a fresh student profile (see #build_student_if_needed).
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
          organization: trainer&.organization || student&.organization || default_organization
        )
        build_student_if_needed(user, student: student, role: role, name: params[:name], email: email)

        if user.save
          audit!("user.register", record: user)
          render_data(session_payload(user), status: :created)
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/google
      # Authenticates via Google OAuth access token. Creates the user account
      # on first access, applying the same trainer/student association logic as /register.
      def google_auth
        userinfo = GoogleAuthService.fetch_userinfo(params[:access_token])
        return render json: { error: "Token do Google inválido" }, status: :unauthorized unless userinfo

        email = userinfo["email"].to_s.downcase.strip
        name  = userinfo["name"].to_s.presence || email.split("@").first

        existing = User.find_by("lower(email) = ?", email)
        if existing
          existing.update_column(:last_login_at, Time.current)
          audit!("user.google_login", record: existing)
          return render_data(session_payload(existing))
        end

        trainer = Trainer.find_by("lower(email) = ?", email)
        student = Student.find_by("lower(email) = ?", email)
        role    = trainer.present? ? "personal" : "student"

        random_password = "#{SecureRandom.hex(16)}Aa1!"
        user = User.new(
          name: name,
          email: email,
          role: role,
          trainer: trainer,
          password: random_password,
          password_confirmation: random_password,
          organization: trainer&.organization || student&.organization || default_organization
        )
        build_student_if_needed(user, student: student, role: role, name: name, email: email)

        if user.save
          audit!("user.google_register", record: user)
          render_data(session_payload(user), status: :created)
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/auth/me
      def me
        render_data(UserSerializer.new(current_user).as_json)
      end

      # PATCH /api/v1/auth/me
      def update_me
        current_user.update!(auth_me_params)
        audit!("user.update_self", record: current_user)
        render_data(UserSerializer.new(current_user).as_json)
      end

      # PATCH /api/v1/auth/password
      def update_password
        unless current_user.authenticate(update_password_params[:current_password])
          return render json: { error: "Senha atual incorreta" }, status: :unauthorized
        end

        current_user.update!(
          password: update_password_params[:password],
          password_confirmation: update_password_params[:password_confirmation]
        )
        audit!("user.change_password", record: current_user)
        render_data({ message: "Senha atualizada com sucesso" })
      end

      # POST /api/v1/auth/password/forgot
      # Always responds with the same generic message regardless of whether
      # the e-mail matches an account — revealing that would let an attacker
      # enumerate registered e-mails. Only sends anything when a match exists.
      def forgot_password
        user = User.find_by("lower(email) = ?", params[:email].to_s.downcase.strip)
        if user
          raw_token = user.generate_password_reset_token!
          PasswordResetMailer.reset_instructions(user, raw_token).deliver_later
          audit!("user.password_reset_requested", record: user)
        end

        render_data({ message: FORGOT_PASSWORD_MESSAGE })
      end

      # POST /api/v1/auth/password/reset
      def reset_password
        user = User.find_by_valid_reset_token(params[:token])
        return render json: { error: "Link inválido ou expirado" }, status: :unprocessable_content if user.nil?

        if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
          user.clear_password_reset_token!
          audit!("user.password_reset", record: user)
          render_data(session_payload(user))
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      # A self-registered "student" always ends up with a real profile: if
      # staff already pre-created a Student row matching this e-mail, link
      # to it; otherwise build a brand-new one now, saved atomically together
      # with `user` by the caller. Without this, the account is left
      # orphaned — invisible in the admin's student listing, and unable to
      # reach any student-scoped page.
      def build_student_if_needed(user, student:, role:, name:, email:)
        if student
          user.student = student
        elsif role == "student"
          user.build_student(name: name, email: email, organization: user.organization)
        end
      end

      # Organização usada quando o cadastro não consegue resolver uma via
      # trainer/student já existente (aluno órfão, autocadastrado sem
      # nenhum convite prévio) — provisório: o fluxo completo de escolha de
      # organização no cadastro (sozinho/entrar/criar) chega numa PR
      # futura; por enquanto usa a organização legada única (só existe 1
      # hoje, criada pela migração de backfill).
      def default_organization
        Organization.first_or_create!(name: "Organização padrão", domain: "organizacao-padrao")
      end

      def auth_me_params
        params.permit(:name, :email)
      end

      def update_password_params
        params.permit(:current_password, :password, :password_confirmation)
      end

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
