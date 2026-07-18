require "rails_helper"

RSpec.describe "Api::V1::Cron", type: :request do
  let(:token) { "test-cron-token-123" }

  around do |example|
    original = ENV["INTERNAL_CRON_TOKEN"]
    ENV["INTERNAL_CRON_TOKEN"] = token
    example.run
    ENV["INTERNAL_CRON_TOKEN"] = original
  end

  describe "POST /api/v1/internal/cron/mark_missed_sessions" do
    it "marks missed sessions and returns the count with a valid token" do
      trainer = create(:trainer)
      student = create(:student, trainer: trainer)
      create(:schedule_session, :planned_in_the_past, student: student, trainer: trainer)

      post "/api/v1/internal/cron/mark_missed_sessions", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["updated"]).to eq(1)
    end

    it "returns 401 without a token" do
      post "/api/v1/internal/cron/mark_missed_sessions"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an incorrect token" do
      post "/api/v1/internal/cron/mark_missed_sessions", headers: { "Authorization" => "Bearer wrong-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not require a user JWT" do
      # Nenhum auth_headers(user) aqui de propósito — é uma rota
      # servidor-a-servidor, não deve passar por Authenticable.
      post "/api/v1/internal/cron/mark_missed_sessions", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
