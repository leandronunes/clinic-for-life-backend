module Api
  module V1
    class StudentMigrationRequestsController < BaseController
      before_action -> { require_role!(:admin) }, only: %i[create]
      before_action :set_request, only: %i[accept reject]
      before_action :authorize_student_owner!, only: %i[accept reject]

      # POST /api/v1/students/migration_requests
      #
      # Admin-only: invites a student who already exists (by e-mail) in another
      # organization to migrate into the current admin's organization. Surfaced
      # to the admin after StudentsController#create returns
      # code: "email_taken_other_organization".
      def create
        target = Student.find_by("lower(email) = ?", params[:email].to_s.downcase.strip)
        return render json: { error: "Nenhum aluno encontrado com este e-mail.", code: "student_not_found" },
                      status: :not_found if target.nil?

        if target.organization_id == current_user.organization_id
          return render json: { error: "Este aluno já pertence à sua organização.",
                                code: "already_in_organization" }, status: :unprocessable_content
        end

        if StudentMigrationRequest.pending.exists?(student_id: target.id)
          return render json: { error: "Já existe uma solicitação de migração pendente para este aluno.",
                                code: "migration_already_pending" }, status: :unprocessable_content
        end

        request = StudentMigrationRequest.create!(
          student: target,
          requested_by: current_user,
          source_organization_id: target.organization_id,
          target_organization_id: current_user.organization_id
        )
        audit!("student_migration_request.create", record: request)
        notify_student(target, request)

        render_data(StudentMigrationRequestSerializer.new(request).as_json, status: :created)
      rescue ActiveRecord::RecordNotUnique
        # Two admins racing to invite the same student concurrently — the
        # exists? check above can't catch this, only the DB's partial unique
        # index can (see CreateStudentMigrationRequests migration).
        render json: { error: "Já existe uma solicitação de migração pendente para este aluno.",
                      code: "migration_already_pending" }, status: :unprocessable_content
      end

      # POST /api/v1/students/migration_requests/:id/accept
      #
      # Self-service only, by the affected student: moves their existing
      # Student/User rows into the target organization in place, preserving all
      # historical child records (they stay attached via student_id, which
      # never changes). trainer_id becomes whoever sent the invite.
      def accept
        ActiveRecord::Base.transaction do
          student = @request.student
          student.update!(organization_id: @request.target_organization_id,
                          trainer_id: @request.requested_by.trainer_id)
          student.user&.update!(organization_id: @request.target_organization_id)
          @request.update!(status: "accepted", responded_at: Time.current)
        end
        audit!("student_migration_request.accept", record: @request)
        render_data(StudentMigrationRequestSerializer.new(@request).as_json)
      end

      # POST /api/v1/students/migration_requests/:id/reject
      def reject
        @request.update!(status: "rejected", responded_at: Time.current)
        audit!("student_migration_request.reject", record: @request)
        render_data(StudentMigrationRequestSerializer.new(@request).as_json)
      end

      private

      def set_request
        @request = StudentMigrationRequest.find(params[:id])
      end

      def authorize_student_owner!
        unless current_user.student? && current_user.student_id == @request.student_id
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        return if @request.pending?

        render json: { error: "Esta solicitação já foi respondida.", code: "migration_request_not_pending" },
              status: :unprocessable_content
      end

      # Best-effort: e-mail always reaches the student even if they haven't
      # registered an account yet; push only fires if they already have one.
      def notify_student(student, request)
        StudentMigrationRequestMailer.invitation(request).deliver_later

        return if student.user.blank?

        PushNotificationJob.perform_later(
          student.user.id,
          title: "Convite para migrar de organização",
          body: "#{current_user.name} convidou você para migrar para a organização " \
                "#{current_user.organization.name}.",
          url: "/aluno"
        )
      end
    end
  end
end
