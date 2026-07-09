require "rails_helper"

RSpec.describe PushNotifier do
  before do
    stub_const("ENV", ENV.to_h.merge(
      "VAPID_SUBJECT" => "mailto:test@forlife.app",
      "VAPID_PUBLIC_KEY" => "test-public-key",
      "VAPID_PRIVATE_KEY" => "test-private-key"
    ))
  end

  describe ".send_to_user" do
    it "does nothing when the user is blank" do
      expect(Webpush).not_to receive(:payload_send)
      described_class.send_to_user(nil, title: "T", body: "B")
    end

    it "sends a payload to every subscription the user has" do
      user = create(:user, :student_account)
      sub1 = create(:push_subscription, user: user)
      sub2 = create(:push_subscription, user: user)
      allow(Webpush).to receive(:payload_send)

      described_class.send_to_user(user, title: "Novo treino!", body: "Push Day", url: "/aluno")

      expect(Webpush).to have_received(:payload_send).with(
        hash_including(endpoint: sub1.endpoint, p256dh: sub1.p256dh_key, auth: sub1.auth_key)
      )
      expect(Webpush).to have_received(:payload_send).with(hash_including(endpoint: sub2.endpoint))
    end

    it "sends the title/body/url as a JSON message payload" do
      user = create(:user, :student_account)
      create(:push_subscription, user: user)
      allow(Webpush).to receive(:payload_send)

      described_class.send_to_user(user, title: "Novo treino!", body: "Push Day", url: "/aluno")

      expect(Webpush).to have_received(:payload_send) do |args|
        expect(JSON.parse(args[:message])).to eq(
          "title" => "Novo treino!", "body" => "Push Day", "url" => "/aluno"
        )
      end
    end

    it "prunes the subscription when the push service reports it expired" do
      user = create(:user, :student_account)
      subscription = create(:push_subscription, user: user)
      allow(Webpush).to receive(:payload_send).and_raise(
        Webpush::ExpiredSubscription.new(instance_double(Net::HTTPResponse, body: "gone"), "fcm.googleapis.com")
      )

      expect do
        described_class.send_to_user(user, title: "T", body: "B")
      end.to change(PushSubscription, :count).by(-1)
      expect(PushSubscription.exists?(subscription.id)).to be(false)
    end

    it "keeps the subscription and logs on a generic response error" do
      user = create(:user, :student_account)
      subscription = create(:push_subscription, user: user)
      allow(Webpush).to receive(:payload_send).and_raise(
        Webpush::ResponseError.new(instance_double(Net::HTTPResponse, body: "oops"), "fcm.googleapis.com")
      )

      expect do
        described_class.send_to_user(user, title: "T", body: "B")
      end.not_to change(PushSubscription, :count)
      expect(PushSubscription.exists?(subscription.id)).to be(true)
    end

    it "does not raise on unexpected errors" do
      user = create(:user, :student_account)
      create(:push_subscription, user: user)
      allow(Webpush).to receive(:payload_send).and_raise(StandardError, "boom")

      expect { described_class.send_to_user(user, title: "T", body: "B") }.not_to raise_error
    end
  end

  # Guards config/initializers/webpush_openssl3_compat.rb: the `webpush` gem
  # (through 1.1.0) generates ephemeral EC keys the old mutable-instance way,
  # which raises OpenSSL::PKey::PKeyError on openssl gem 3.0+. These exercise
  # the real (unmocked) gem methods our initializer patches, so a stale patch
  # or an accidental deletion of the initializer fails loudly here instead of
  # silently breaking every real push send.
  describe "OpenSSL 3.0 compatibility patch" do
    it "generates a VAPID keypair without raising" do
      expect { Webpush.generate_key }.not_to raise_error
    end

    it "encrypts a push payload without raising" do
      client_key = OpenSSL::PKey::EC.generate("prime256v1")
      p256dh = Webpush.encode64(client_key.public_key.to_bn.to_s(2))
      auth = Webpush.encode64(SecureRandom.random_bytes(16))

      expect { Webpush::Encryption.encrypt("hello", p256dh, auth) }.not_to raise_error
    end
  end

  # Guards config/initializers/webpush_ruby3_kwargs_compat.rb: the `webpush`
  # gem (0.3.2) passes the subscription's :keys Hash as a second positional
  # argument to a method that declares p256dh:/auth: as required keywords —
  # fine under Ruby < 3.0's implicit Hash-to-keywords conversion, but an
  # ArgumentError on this app's Ruby. PushNotifier's other specs stub
  # Webpush.payload_send, so only building a real Webpush::Request (as every
  # actual send does) exercises the patched code path.
  describe "Ruby 3 keyword arguments compatibility patch" do
    it "builds an encrypted payload without raising" do
      client_key = OpenSSL::PKey::EC.generate("prime256v1")
      p256dh = Webpush.encode64(client_key.public_key.to_bn.to_s(2))
      auth = Webpush.encode64(SecureRandom.random_bytes(16))

      expect do
        Webpush::Request.new(
          message: "hello",
          subscription: { endpoint: "https://fcm.googleapis.com/fcm/send/abc", keys: { p256dh: p256dh, auth: auth } },
          vapid: { subject: "mailto:test@forlife.app", public_key: "pub", private_key: "priv" }
        )
      end.not_to raise_error
    end
  end
end
