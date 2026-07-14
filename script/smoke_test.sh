#!/usr/bin/env bash
# Post-deploy smoke test against a real production environment. Run by
# .github/workflows/release.yml right after the Render deploy hook fires —
# never run against a local/dev environment on purpose.
set -euo pipefail

: "${SMOKE_BASE_URL:?SMOKE_BASE_URL não configurado}"
: "${SMOKE_EMAIL:?SMOKE_EMAIL não configurado}"
: "${SMOKE_PASSWORD:?SMOKE_PASSWORD não configurado}"

echo "==> Health check: GET $SMOKE_BASE_URL/up"
curl -fsS -o /dev/null "$SMOKE_BASE_URL/up"
echo "OK"

echo "==> Login: POST $SMOKE_BASE_URL/api/v1/auth/login"
LOGIN_RESPONSE=$(curl -fsS -X POST "$SMOKE_BASE_URL/api/v1/auth/login" \
  -d "email=$SMOKE_EMAIL" \
  -d "password=$SMOKE_PASSWORD")
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -er '.data.token')
echo "OK"

# Also proves DB connectivity — the endpoint loads the authenticated user
# from the database, so a separate DB-only health check isn't needed.
echo "==> Authenticated request: GET $SMOKE_BASE_URL/api/v1/auth/me"
curl -fsS -o /dev/null -H "Authorization: Bearer $TOKEN" "$SMOKE_BASE_URL/api/v1/auth/me"
echo "OK"

echo "==> Smoke test passed"
