class PartnerSerializer
  def initialize(partner)
    @partner = partner
  end

  def as_json(*)
    {
      id: @partner.id.to_s,
      name: @partner.name,
      logo_url: @partner.logo_url,
      category: @partner.category,
      description: @partner.description,
      coupon: @partner.coupon,
      link: @partner.link,
      created_at: @partner.created_at&.to_date&.iso8601
    }
  end
end
