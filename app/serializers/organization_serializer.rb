class OrganizationSerializer
  def initialize(organization)
    @organization = organization
  end

  def as_json(*)
    {
      id: @organization.id.to_s,
      name: @organization.name,
      domain: @organization.domain
    }
  end
end
