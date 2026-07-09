# The `webpush` gem (verified through 1.1.0, the latest release) generates
# ephemeral EC keys the old, mutable-instance way:
#
#   key = OpenSSL::PKey::EC.new(curve_name)
#   key.generate_key
#
# On openssl gem 3.0+ (bundled with Ruby's OpenSSL 3.0 bindings), EC keys are
# immutable once constructed — `generate_key`/`generate_key!` on an instance
# raises `OpenSSL::PKey::PKeyError: pkeys are immutable on OpenSSL 3.0`. The
# fix is the modern class method `OpenSSL::PKey::EC.generate(curve_name)`,
# which returns an already-populated key instead of mutating one in place.
#
# This breaks two things in the gem: Webpush::VapidKey#initialize (used by
# Webpush.generate_key, i.e. the command documented in .env.example to
# generate a VAPID keypair) and, more importantly, Webpush::Encryption#encrypt
# — called on *every* real push send that includes a message body, i.e.
# every notification we send. Patch just these two methods here rather than
# touching the gem or downgrading the app-wide `openssl` gem (used by JWT
# signing, bcrypt, S3 request signing, etc.) for one vendor's outdated
# key-generation call.
#
# Remove this file once a `webpush` release fixes it upstream.
module Webpush
  class VapidKey
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end
  end

  module Encryption
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = salt.to_s + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
