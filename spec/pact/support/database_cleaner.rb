# Provider verification drives real HTTP requests against a booted Rack app —
# a different thread/connection than the one running this RSpec example — so
# `config.use_transactional_fixtures` (spec/rails_helper.rb) cannot make setup
# data visible to it: Postgres never exposes an uncommitted transaction across
# connections. Truncation is scoped to this suite only; the main spec/rails_helper.rb
# suite is untouched and keeps using (faster, zero-cleanup-risk) transactional fixtures.
require "database_cleaner/active_record"

# `DatabaseCleaner.clean_with(:truncation)` (a one-shot call, not the
# `.strategy =`/`.clean` pair) so every call is self-contained regardless of
# which thread/connection it runs on — provider_state setup blocks call this
# directly (see spec/pact/consumers/*_spec.rb) since it must be idempotent:
# the FFI verifier retries a failed state setup a few times before giving up.
def clean_database!
  DatabaseCleaner.clean_with(:truncation)
end

RSpec.configure do |config|
  config.before(:each, pact_entity: :provider) { clean_database! }
  config.after(:each, pact_entity: :provider) { PactStateContext.clear }
end
