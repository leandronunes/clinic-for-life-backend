require "rails_helper"

RSpec.describe "Api::V1::PushSubscriptions", type: :request do
  let(:student_user) { create(:user, :student_account) }
  let(:params) do
    { endpoint: "https://fcm.googleapis.com/fcm/send/abc123",
      keys: { p256dh: "BExampleKey", auth: "authExampleSecret" } }
  end

  describe "POST /api/v1/push_subscriptions" do
    it "creates a subscription owned by the current user" do
      expect do
        post "/api/v1/push_subscriptions", params: params, headers: auth_headers(student_user)
      end.to change(PushSubscription, :count).by(1)

      expect(response).to have_http_status(:created)
      subscription = student_user.push_subscriptions.find_by(endpoint: params[:endpoint])
      expect(subscription.p256dh_key).to eq("BExampleKey")
      expect(subscription.auth_key).to eq("authExampleSecret")
    end

    it "updates the existing subscription instead of duplicating it when the endpoint repeats" do
      post "/api/v1/push_subscriptions", params: params, headers: auth_headers(student_user)

      expect do
        post "/api/v1/push_subscriptions",
             params: params.merge(keys: { p256dh: "NewKey", auth: "NewAuth" }),
             headers: auth_headers(student_user)
      end.not_to change(PushSubscription, :count)

      subscription = student_user.push_subscriptions.find_by(endpoint: params[:endpoint])
      expect(subscription.p256dh_key).to eq("NewKey")
    end

    it "rejects a subscription without keys" do
      post "/api/v1/push_subscriptions", params: { endpoint: params[:endpoint] },
                                          headers: auth_headers(student_user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/push_subscriptions", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/push_subscriptions" do
    it "removes the subscription matching the given endpoint" do
      create(:push_subscription, user: student_user, endpoint: params[:endpoint])

      expect do
        delete "/api/v1/push_subscriptions", params: { endpoint: params[:endpoint] },
                                              headers: auth_headers(student_user)
      end.to change(PushSubscription, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "is idempotent when the endpoint does not exist" do
      delete "/api/v1/push_subscriptions", params: { endpoint: "https://unknown" },
                                            headers: auth_headers(student_user)

      expect(response).to have_http_status(:no_content)
    end
  end
end
