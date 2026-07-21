# Lives under spec/pact/consumers/ on purpose, not spec/pact/consumers/providers/ —
# pact/rspec derives `pact_entity: :provider` from the "consumers" directory name
# (it names directories after "the other side", so this reads as "specs verifying
# our consumers"). See spec/pact/pact_helper.rb for the require chain.
#
# http_pact_provider may only be declared ONCE per RSpec run — the pact-ffi
# verifier replays every interaction in the whole pact source (broker or
# local file/directory) in a single generated example, so this is the one and
# only file that calls it. Every domain's provider_state registrations live
# in spec/pact/support/states/<domain>.rb and get pulled in below via
# `instance_eval` (provider_state is a DSL method only available inside this
# example group's context — see docs/pact.md for how to add a new domain).
RSpec.describe "Clinic For Life API" do
  # http_port must be a fixed, real port rather than the 0 (OS-assigned)
  # default: the FFI verifier is told the port via set_provider_info *before*
  # WEBrick actually binds one, so with an ephemeral port the verifier and the
  # booted app end up disagreeing on where to send requests (every request
  # then 404s against the wrong port).
  http_pact_provider "clinic-for-life-backend", opts: {
    app: PactAuthOverride.new(Rails.application),
    http_port: ENV.fetch("PACT_PROVIDER_HTTP_PORT", 4567).to_i
  }

  instance_eval(&PactStates::Partners.definitions)
  instance_eval(&PactStates::Auth.definitions)
  instance_eval(&PactStates::Students.definitions)
  instance_eval(&PactStates::Trainers.definitions)
  instance_eval(&PactStates::Workouts.definitions)
  instance_eval(&PactStates::Anamnesis.definitions)
  instance_eval(&PactStates::StructuralAssessmentStates.definitions)
  instance_eval(&PactStates::Biomechanics.definitions)
  instance_eval(&PactStates::Evolution.definitions)
  instance_eval(&PactStates::Bioimpedance.definitions)
  instance_eval(&PactStates::Exams.definitions)
  instance_eval(&PactStates::Dashboard.definitions)
  instance_eval(&PactStates::Uploads.definitions)
  instance_eval(&PactStates::PushSubscriptions.definitions)
  instance_eval(&PactStates::CheckIns.definitions)
  instance_eval(&PactStates::Feedbacks.definitions)
  instance_eval(&PactStates::CompletedCheckIns.definitions)
  instance_eval(&PactStates::AttendanceCycles.definitions)
  instance_eval(&PactStates::Chat.definitions)
end
