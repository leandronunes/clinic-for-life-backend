class StudentMigrationRequestSerializer
  def initialize(request)
    @request = request
  end

  def as_json(*)
    {
      id: @request.id.to_s,
      status: @request.status,
      target_organization_name: @request.target_organization.name,
      requested_by_name: @request.requested_by.name,
      created_at: @request.created_at&.iso8601
    }
  end
end
