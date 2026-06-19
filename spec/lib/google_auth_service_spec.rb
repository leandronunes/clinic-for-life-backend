require "rails_helper"

RSpec.describe GoogleAuthService do
  describe ".fetch_userinfo" do
    let(:access_token) { "valid-google-access-token" }
    let(:userinfo_body) { '{"email":"user@example.com","name":"Test User","sub":"12345"}' }

    def stub_google_response(body:, success: true)
      response = double("http_response", body: body)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
      allow(Net::HTTP).to receive(:start).and_return(response)
      response
    end

    it "retorna o hash de userinfo quando o Google responde com sucesso" do
      stub_google_response(body: userinfo_body)

      result = described_class.fetch_userinfo(access_token)

      expect(result).to eq({
        "email" => "user@example.com",
        "name"  => "Test User",
        "sub"   => "12345"
      })
    end

    it "inclui o header Authorization com o access token" do
      captured_request = nil
      response = double("http_response", body: userinfo_body)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      allow(Net::HTTP).to receive(:start) do |*_args, &block|
        http_stub = double("net_http")
        allow(http_stub).to receive(:request) do |req|
          captured_request = req
          response
        end
        block.call(http_stub)
      end

      described_class.fetch_userinfo(access_token)

      expect(captured_request["Authorization"]).to eq("Bearer #{access_token}")
    end

    it "retorna nil quando a resposta do Google não é 2xx" do
      stub_google_response(body: '{"error":"invalid_token"}', success: false)

      expect(described_class.fetch_userinfo(access_token)).to be_nil
    end

    it "retorna nil quando o access_token é uma string vazia" do
      expect(Net::HTTP).not_to receive(:start)
      expect(described_class.fetch_userinfo("")).to be_nil
    end

    it "retorna nil quando o access_token é nil" do
      expect(described_class.fetch_userinfo(nil)).to be_nil
    end

    it "retorna nil quando ocorre um erro de rede" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "Failed to open TCP connection")

      expect(described_class.fetch_userinfo(access_token)).to be_nil
    end

    it "retorna nil quando o corpo da resposta não é JSON válido" do
      stub_google_response(body: "not-json")

      expect(described_class.fetch_userinfo(access_token)).to be_nil
    end
  end
end
