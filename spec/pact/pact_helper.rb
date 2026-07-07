# Loaded via `.rspec-pact`'s `--require spec/pact/pact_helper`, kept completely
# separate from spec/rails_helper.rb: provider verification specs run outside
# SimpleCov's coverage gate and outside the transactional-fixtures suite (see
# spec/pact/support/database_cleaner.rb for why). Never require this file, or
# anything under spec/pact/, from spec/rails_helper.rb.
require "pact/rspec"

ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require_relative "support/jwt_fixtures"
require_relative "support/database_cleaner"
require_relative "support/webrick_patch"

# One file per domain, each defining a `PactStates::<Domain>.definitions`
# proc — see spec/pact/consumers/backend_provider_spec.rb for how they're
# wired in, and docs/pact.md for how to add a new one.
Dir[File.join(__dir__, "support/states/*.rb")].sort.each { |f| require_relative f }
