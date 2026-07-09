class PushSubscriptionSerializer
  def initialize(subscription)
    @subscription = subscription
  end

  def as_json(*)
    {
      id: @subscription.id.to_s,
      endpoint: @subscription.endpoint,
      created_at: @subscription.created_at&.iso8601
    }
  end
end
