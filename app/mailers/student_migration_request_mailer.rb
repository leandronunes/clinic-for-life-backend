class StudentMigrationRequestMailer < ApplicationMailer
  def invitation(migration_request)
    @request = migration_request
    @student = migration_request.student
    @organization = migration_request.target_organization
    @requested_by = migration_request.requested_by
    @login_url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:5173")}/login"

    mail(to: @student.email, subject: "Convite para migrar de organização — Núcleo For Life")
  end
end
