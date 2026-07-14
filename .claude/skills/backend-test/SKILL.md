---
name: backend-test
description: Use whenever writing or updating RSpec specs in this repo (clinic-for-life-backend) — a new/changed model, controller action, service, or job needs a model spec and/or request spec. Covers the auth/request-spec conventions, FactoryBot usage, status-code gotchas, and the SimpleCov coverage gate so specs match the rest of the suite instead of re-deriving the boilerplate each time.
---

# Backend tests (RSpec)

CLAUDE.md requires a spec for everything created/changed (model spec, request
spec, or both), and `bundle exec rspec` must pass with **line coverage ≥ 90%**
(SimpleCov). This skill is the concrete "how" for this repo.

## Before writing anything

Find the closest existing spec under `spec/requests/api/v1/` or `spec/models/`
for a similar resource and match its shape — the conventions below are already
followed consistently across `spec/`.

## Request specs

```ruby
require "rails_helper"

RSpec.describe "Api::V1::Whatever", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/students/:student_id/whatever" do
    it "returns the resource for the student's own personal" do
      get "/api/v1/students/#{student.id}/whatever", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to ...
    end

    it "forbids a personal outside the student's portfolio" do
      other_personal = create(:user, :personal)
      get "/api/v1/students/#{student.id}/whatever", headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "allows an admin to view any student's data" do
      get "/api/v1/students/#{student.id}/whatever", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end
end
```

Rules this encodes:
- **Auth via the `auth_headers(user)` helper** (`spec/support/auth_helpers.rb`,
  auto-included for `type: :request`) — builds a real JWT with
  `JsonWebToken.encode({ sub:, email:, role: })`. Never hand-roll a token.
- **Parse responses with `json_body`**, not `JSON.parse(response.body)` inline.
- **`create`/`build` are available directly** — `FactoryBot::Syntax::Methods` is
  globally included in `rails_helper.rb`, no `FactoryBot.` prefix needed.
- **Cover every role boundary** for a scoped endpoint: the owning personal (or
  the student themself), a personal outside the portfolio (→ `:forbidden`), and
  admin (→ always allowed). This mirrors the role table in the backend
  CLAUDE.md (admin/personal/student).
- **422 is `:unprocessable_content`**, not `:unprocessable_entity` — Rails
  8/Rack 3 renamed it; using the old symbol will make the assertion silently
  compare against the wrong status.

## Model specs

Validate presence/format/uniqueness, associations with the right `dependent:`,
and any domain invariants the model enforces. Use factories, not raw
`Model.new(...)` with every column filled in by hand.

**Don't use shoulda's `validate_uniqueness_of` on a numeric column** — it's
flaky against numeric columns in this stack. Use the equivalent manual check
instead:
```ruby
it "requires a unique cpf" do
  create(:student, cpf: "12345678900")
  expect(build(:student, cpf: "12345678900")).not_to be_valid
end
```

## FactoryBot

Add a factory in `spec/factories/` next to the model when creating a new one —
`association :student`/`association :trainer` for required relations, minimal
valid defaults for the rest, `trait`s for variant states (see
`spec/factories/check_in_feedbacks.rb`'s `:with_emoji` / `:with_message_and_emoji`
for the pattern). No network dependency, ever.

## Database

If specs fail because the schema is out of date:
```bash
RAILS_ENV=test bin/rails db:test:prepare
```

## Out of scope for this skill

- **Pact provider verification** (`bundle exec rake pact:verify`) is a separate
  suite from `bundle exec rspec` and doesn't count toward SimpleCov coverage —
  see `docs/pact.md`. When an endpoint consumed by the frontend changes, update
  the matching provider state in `spec/pact/support/states/` (registered in
  `spec/pact/consumers/backend_provider_spec.rb`) in the same PR.
- **Swagger docs** (`swagger/v1/swagger.yaml`) aren't a test, but CLAUDE.md
  requires updating them in the same PR as any endpoint change — validate with
  `npx @redocly/cli lint swagger/v1/swagger.yaml`.

## Before reporting done

Run `bundle exec rspec` (coverage ≥ 90%) and `bin/rubocop` — both must pass.
