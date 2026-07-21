require "rails_helper"

RSpec.describe ScheduleSessionLinkerService do
  let(:trainer) { create(:trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:workout) { create(:workout, student: student) }

  # Builds a completed + personal-confirmed check-in with a controlled
  # created_at, WITHOUT ever satisfying WorkoutCheckIn's own
  # ready_for_schedule_link? callback along the way (update_columns skips
  # callbacks) — so these specs exercise the service in isolation, not the
  # model's callback wiring (that's covered in workout_check_in_spec.rb).
  def build_check_in(workout:, started_at:)
    check_in = create(:workout_check_in, workout: workout, status: "in_progress")
    check_in.update_columns(status: "completed", completed_at: Time.current,
                            personal_confirmed_at: Time.current, created_at: started_at)
    check_in.reload
  end

  describe ".call" do
    it "links an existing planned session for that day even when the time doesn't match" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))

      described_class.call(check_in)

      expect(session.reload.status).to eq("done")
      expect(session.workout_check_in_id).to eq(check_in.id)
    end

    it "links an existing missed session for that day (confirmed after the planned time already passed)" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "missed", starts_at: Time.zone.now.change(hour: 7))
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))

      described_class.call(check_in)

      expect(session.reload.status).to eq("done")
      expect(session.workout_check_in_id).to eq(check_in.id)
    end

    it "ignores an already-linked (done) session as a candidate and creates a new one instead" do
      other_check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 6))
      already_linked = create(:schedule_session, student: student, trainer: trainer, status: "done",
                                                  starts_at: Time.zone.now.change(hour: 7),
                                                  workout_check_in: other_check_in)
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))

      expect { described_class.call(check_in) }.to change(ScheduleSession, :count).by(1)
      expect(already_linked.reload.workout_check_in_id).to eq(other_check_in.id)
      new_session = ScheduleSession.find_by(workout_check_in_id: check_in.id)
      expect(new_session).to be_present
      expect(new_session.starts_at).to be_within(1.second).of(check_in.created_at)
    end

    it "ignores a canceled session as a candidate and creates a new one instead" do
      create(:schedule_session, student: student, trainer: trainer, status: "canceled",
                                 starts_at: Time.zone.now.change(hour: 7))
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))

      expect { described_class.call(check_in) }.to change(ScheduleSession, :count).by(1)
    end

    it "creates a new 60-minute session at the check-in's start time when none exists that day" do
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 18, min: 30))

      expect { described_class.call(check_in) }.to change(ScheduleSession, :count).by(1)

      session = ScheduleSession.find_by(workout_check_in_id: check_in.id)
      expect(session.student_id).to eq(student.id)
      expect(session.trainer_id).to eq(trainer.id)
      expect(session.duration_minutes).to eq(60)
      expect(session.status).to eq("done")
      expect(session.workout_id).to eq(check_in.workout_id)
      expect(session.starts_at).to be_within(1.second).of(check_in.created_at)
    end

    it "does not link to another student's session that day" do
      other_student = create(:student, trainer: trainer)
      create(:schedule_session, student: other_student, trainer: trainer,
                                 status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 8))

      expect { described_class.call(check_in) }.to change(ScheduleSession, :count).by(1)
    end

    it "picks the candidate session closest in time when more than one exists that day" do
      far = create(:schedule_session, student: student, trainer: trainer,
                                       status: "planned", starts_at: Time.zone.now.change(hour: 6))
      near = create(:schedule_session, student: student, trainer: trainer,
                                        status: "planned", starts_at: Time.zone.now.change(hour: 18))
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))

      described_class.call(check_in)

      expect(near.reload.workout_check_in_id).to eq(check_in.id)
      expect(far.reload.workout_check_in_id).to be_nil
    end

    it "is idempotent — calling again for an already-linked check-in does nothing" do
      check_in = build_check_in(workout: workout, started_at: Time.zone.now.change(hour: 19))
      described_class.call(check_in)

      expect { described_class.call(check_in) }.not_to change(ScheduleSession, :count)
    end

    it "does not create or link anything when the student has no trainer" do
      trainerless_student = create(:student, trainer: nil)
      trainerless_workout = create(:workout, student: trainerless_student)
      check_in = build_check_in(workout: trainerless_workout, started_at: Time.zone.now.change(hour: 19))

      expect { described_class.call(check_in) }.not_to change(ScheduleSession, :count)
    end
  end
end
