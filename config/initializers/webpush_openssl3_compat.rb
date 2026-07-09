# The `webpush` gem this app locks to (0.3.2) generates ephemeral EC keys the
# old, mutable-instance way:
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
# This breaks three things in the gem: Webpush::VapidKey#initialize (used by
# Webpush.generate_key, i.e. the command documented in .env.example to
# generate a VAPID keypair); Webpush::Encryption#encrypt, called on every real
# push send that includes a message body; and Webpush::VapidKey.from_keys
# (used by Webpush::Request#build_vapid_headers on *every* real send,
# regardless of message body, to sign the VAPID JWT with the app's own keys)
# — its #public_key=/#private_key= setters mutate @curve in two steps after
# construction, which is exactly the immutable-key pattern this whole file
# exists to avoid. Rebuild the key from a DER-encoded ECPrivateKey structure
# (RFC 5915) in one shot instead of generate-then-mutate. Patch these here
# rather than touching the gem or downgrading the app-wide `openssl` gem
# (used by JWT signing, bcrypt, S3 request signing, etc.) for one vendor's
# outdated key-generation call.
#
# IMPORTANT: 0.3.2 uses the older "aesgcm" encryption scheme and returns a
# Hash (`{ ciphertext:, salt:, server_public_key:, ... }`), which
# Webpush::Request#headers/#dh_param/#salt_param depend on — NOT the newer
# "aes128gcm" scheme (RFC 8188, a raw binary string) used by later gem
# versions. The patch below is copied from 0.3.2's own encrypt method with
# only the two key-generation lines changed; do not "upgrade" it to the
# aes128gcm shape without also bumping the gem version, or Request#headers
# breaks with NoMethodError on the resulting String.
#
# Remove this file once a `webpush` release fixes it upstream.
module Webpush
  class VapidKey
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end

    def self.from_keys(encoded_public_key, encoded_private_key)
      group = OpenSSL::PKey::EC::Group.new("prime256v1")
      public_key_bn = OpenSSL::BN.new(Webpush.decode64(encoded_public_key), 2)
      private_key_bn = OpenSSL::BN.new(Webpush.decode64(encoded_private_key), 2)
      point = OpenSSL::PKey::EC::Point.new(group, public_key_bn)

      der = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(1),
        OpenSSL::ASN1::OctetString(private_key_bn.to_s(2)),
        OpenSSL::ASN1::ObjectId("prime256v1", 0, :EXPLICIT),
        OpenSSL::ASN1::BitString(point.to_octet_string(:uncompressed), 1, :EXPLICIT)
      ]).to_der

      key = new
      key.instance_variable_set(:@curve, OpenSSL::PKey::EC.new(der))
      key
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

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256",
                      info: "Content-Encoding: auth\0").next_bytes(32)

      context = create_context(client_public_key_bn, server_public_key_bn)

      content_encryption_key_info = create_info("aesgcm", context)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce_info = create_info("nonce", context)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      {
        ciphertext: ciphertext,
        salt: salt,
        server_public_key_bn: convert16bit(server_public_key_bn),
        server_public_key: server_public_key_bn.to_s(2),
        shared_secret: shared_secret
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
