# Provider verification only — this app never plays consumer, so there is no
# `pact:publish` task here. Publishing pacts and running `can-i-deploy` are
# consumer-side (frontend) concerns; see docs/pact.md for the equivalent
# frontend npm scripts, and `bundle exec pact-broker can-i-deploy` (from the
# pact_broker-client gem) for the pre-deploy gate on this side.
begin
  require "rspec/core/rake_task"

  namespace :pact do
    desc "Verify this API against the frontend's published/local pact contracts"
    RSpec::Core::RakeTask.new(:verify) do |t|
      t.rspec_opts = "-O .rspec-pact"
      t.pattern = "spec/pact/consumers/**/*_spec.rb"
    end
  end
rescue LoadError
  # rspec-rails isn't bundled in this environment (e.g. production) — pact:verify
  # simply won't be defined there, matching how bundle exec rspec itself behaves.
end
