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
      #
      # Self-service registration. Associates the new user account with an
      # existing trainer or student record when the e-mail matches one
      # (staff already pre-created the professional/student profile).
      # Otherwise: role == "student" builds a fresh orphan student profile
      # (#build_student_if_needed); role == "personal" creates a brand-new
      # Trainer per trainer_mode (#build_trainer_for_registration!) — solo
      # (own private organization, self-approved), create_org (new
      # organization, self-approved as its founder), or join (existing
      # organization by id, pending that organization's admin approval —
      # see Authorizable#block_if_pending_trainer!).
      def register
        email = params[:email].to_s.downcase.strip

        if User.exists?(email: email)
          return render json: { error: "E-mail já possui uma conta cadastrada" },
                        status: :unprocessable_entity
        end

        user = nil
        ActiveRecord::Base.transaction do
          user = build_registration_user(email: email, name: params[:name])
          user.password = params[:password]
          user.password_confirmation = params[:password_confirmation]
          user.save!
        end

        audit!("user.register", record: user)
        render_data(session_payload(user), status: :created)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # POST /api/v1/auth/google
      # Authenticates via Google OAuth access token. Creates the user account
      # on first access, applying the same trainer/student association logic
      # as /register — including role/trainer_mode, if sent (see
      # #build_registration_user). Google's own flow is single-shot (no
      # multi-step UI mid-redirect), so the frontend never actually offers
      # join/create_org before this call — a new personal via Google always
      # ends up "solo" in practice, simply by never sending trainer_mode.
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

        random_password = "#{SecureRandom.hex(16)}Aa1!"
        user = nil
        ActiveRecord::Base.transaction do
          user = build_registration_user(email: email, name: name)
          user.password = random_password
          user.password_confirmation = random_password
          user.save!
        end

        audit!("user.google_register", record: user)
        render_data(session_payload(user), status: :created)
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
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

      # Resolves role + trainer/student + organization for a brand-new User
      # (shared by #register and #google_auth — kept in sync deliberately,
      # since letting the two entry points diverge is exactly how a "claim
      # the pre-created profile by e-mail" bug would sneak in for one path
      # but not the other). Does NOT persist — caller sets password and saves.
      def build_registration_user(email:, name:)
        trainer = Trainer.find_by("lower(email) = ?", email)
        student = Student.find_by("lower(email) = ?", email)
        trainer ||= build_trainer_for_registration!(name: name, email: email) if params[:role] == "personal"
        role = trainer.present? ? "personal" : "student"

        user = User.new(
          name: name,
          email: email,
          role: role,
          trainer: trainer,
          organization: trainer&.organization || student&.organization || default_organization
        )
        build_student_if_needed(user, student: student, role: role, name: name, email: email)
        user
      end

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

      # Only reached when role == "personal" and no pre-existing Trainer
      # matched the e-mail (that legacy "claim your pre-created profile"
      # case is resolved by the caller before this ever runs). trainer_mode
      # picks the path:
      # - "join": existing organization by id, pending that org's admin
      #   approval (approved_at nil — see Authorizable#block_if_pending_trainer!).
      # - "create_org": brand-new organization with the given name/domain,
      #   self-approved (this trainer IS its founding admin).
      # - anything else (including absent, e.g. every Google signup today):
      #   defaults to "solo" — a private organization auto-generated for
      #   just this trainer, self-approved.
      def build_trainer_for_registration!(name:, email:)
        case params[:trainer_mode]
        when "join"
          organization = Organization.find(params[:organization_id])
          Trainer.create!(name: name, email: email, organization: organization, approved_at: nil)
        when "create_org"
          organization = Organization.create!(name: params[:organization_name], domain: params[:organization_domain])
          Trainer.create!(name: name, email: email, organization: organization, approved_at: Time.current)
        else
          organization = Organization.create!(name: "#{name} (individual)", domain: SecureRandom.hex(4))
          Trainer.create!(name: name, email: email, organization: organization, approved_at: Time.current)
        end
      end

      # Organização usada quando o autocadastro de aluno não encontra
      # nenhum Student pré-existente por e-mail (aluno órfão, sem convite
      # prévio de nenhum personal/organização) — cai na organização legada
      # única (mesmo bucket dos dados pré-migração).
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
