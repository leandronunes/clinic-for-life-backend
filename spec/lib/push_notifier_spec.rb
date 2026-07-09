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
      expect(WebPush).not_to receive(:payload_send)
      described_class.send_to_user(nil, title: "T", body: "B")
    end

    it "sends a payload to every subscription the user has" do
      user = create(:user, :student_account)
      sub1 = create(:push_subscription, user: user)
      sub2 = create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send)

      described_class.send_to_user(user, title: "Novo treino!", body: "Push Day", url: "/aluno")

      expect(WebPush).to have_received(:payload_send).with(
        hash_including(endpoint: sub1.endpoint, p256dh: sub1.p256dh_key, auth: sub1.auth_key)
      )
      expect(WebPush).to have_received(:payload_send).with(hash_including(endpoint: sub2.endpoint))
    end

    it "sends the title/body/url as a JSON message payload" do
      user = create(:user, :student_account)
      create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send)

      described_class.send_to_user(user, title: "Novo treino!", body: "Push Day", url: "/aluno")

      expect(WebPush).to have_received(:payload_send) do |args|
        expect(JSON.parse(args[:message])).to eq(
          "title" => "Novo treino!", "body" => "Push Day", "url" => "/aluno"
        )
      end
    end

    it "prunes the subscription when the push service reports it expired" do
      user = create(:user, :student_account)
      subscription = create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send).and_raise(
        WebPush::ExpiredSubscription.new(instance_double(Net::HTTPResponse, body: "gone"), "fcm.googleapis.com")
      )

      expect do
        described_class.send_to_user(user, title: "T", body: "B")
      end.to change(PushSubscription, :count).by(-1)
      expect(PushSubscription.exists?(subscription.id)).to be(false)
    end

    it "keeps the subscription and logs on a generic response error" do
      user = create(:user, :student_account)
      subscription = create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send).and_raise(
        WebPush::ResponseError.new(instance_double(Net::HTTPResponse, body: "oops"), "fcm.googleapis.com")
      )

      expect do
        described_class.send_to_user(user, title: "T", body: "B")
      end.not_to change(PushSubscription, :count)
      expect(PushSubscription.exists?(subscription.id)).to be(true)
    end

    it "does not raise on unexpected errors" do
      user = create(:user, :student_account)
      create(:push_subscription, user: user)
      allow(WebPush).to receive(:payload_send).and_raise(StandardError, "boom")

      expect { described_class.send_to_user(user, title: "T", body: "B") }.not_to raise_error
    end
  end

  # End-to-end smoke test against the real (unmocked) `web-push` gem, not just
  # PushNotifier's own logic (which the specs above stub WebPush.payload_send
  # for). We previously vendored monkey-patches for the older `webpush` gem
  # to work around OpenSSL 3.0/Ruby 3 incompatibilities in its internals, and
  # got burned twice by "does not raise" assertions that passed despite the
  # patches being subtly wrong. `web-push` (the actively maintained Pushpad
  # fork this app now uses) doesn't need any patch, but keep this test as a
  # tripwire: it builds a real request, signs it with a real VAPID keypair,
  # and asserts on the actual header/body shape rather than just "no error".
  describe "real push request pipeline" do
    it "builds and signs a push request with the expected headers and body" do
      client_key = OpenSSL::PKey::EC.generate("prime256v1")
      p256dh = WebPush.encode64(client_key.public_key.to_bn.to_s(2))
      auth = WebPush.encode64(SecureRandom.random_bytes(16))
      vapid_key = WebPush.generate_key

      request = WebPush::Request.new(
        message: "hello",
        subscription: { endpoint: "https://fcm.googleapis.com/fcm/send/abc", keys: { p256dh: p256dh, auth: auth } },
        vapid: { subject: "mailto:test@forlife.app", public_key: vapid_key.public_key, private_key: vapid_key.private_key }
      )

      headers = request.headers

      expect(headers["Content-Encoding"]).to eq("aes128gcm")
      expect(headers).to include("Authorization")
      expect(request.body).not_to be_empty
    end
  end
end
