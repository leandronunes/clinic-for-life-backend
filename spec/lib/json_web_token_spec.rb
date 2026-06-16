require "rails_helper"

RSpec.describe JsonWebToken do
  let(:payload) { { sub: 42, email: "user@forlife.app", role: "admin" } }

  describe ".encode / .decode round trip" do
    it "encodes and decodes the payload" do
      token = described_class.encode(payload)
      decoded = described_class.decode(token)
      expect(decoded[:sub]).to eq(42)
      expect(decoded[:email]).to eq("user@forlife.app")
      expect(decoded[:role]).to eq("admin")
    end

    it "adds an expiration claim" do
      token = described_class.encode(payload)
      expect(described_class.decode(token)[:exp]).to be_present
    end

    it "does not mutate the original payload" do
      described_class.encode(payload)
      expect(payload).not_to have_key(:exp)
    end
  end

  describe ".decode failure handling" do
    it "returns nil for a malformed token" do
      expect(described_class.decode("not.a.jwt")).to be_nil
    end

    it "returns nil for an expired token" do
      token = described_class.encode(payload, exp: 1.hour.ago)
      expect(described_class.decode(token)).to be_nil
    end
  end
end
