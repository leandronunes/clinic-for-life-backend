# Test-only, provider-verification-only patch — never loaded outside
# spec/pact/pact_helper.rb, never affects production (which runs Puma, not
# WEBrick).
#
# `pact` boots the app under verification via WEBrick (hardcoded inside the
# gem — see Pact::Provider::HttpServer). WEBrick raises 411 Length Required
# for any bare POST/PUT with neither Content-Length nor Transfer-Encoding
# (webrick/httprequest.rb), which real action-style endpoints legitimately
# send with no body at all (e.g. POST .../archive). Real browsers, Puma, and
# the frontend's own http client never hit this — it is purely an artifact of
# WEBrick's stricter-than-necessary interpretation of RFC 7230 for this one
# test server, so it's patched away here rather than papering over it by
# inventing a fake request body in the consumer contract.
require "webrick"

WEBrick::HTTPRequest::BODY_CONTAINABLE_METHODS = [].freeze
