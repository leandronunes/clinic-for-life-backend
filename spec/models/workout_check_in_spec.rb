require "rails_helper"

RSpec.describe WorkoutCheckIn do
  it "is invalid with a status outside STATUSES" do
    check_in = build(:workout_check_in, status: "bogus")
    expect(check_in).not_to be_valid
  end

  it "rejects a second in-progress check-in for the same workout at the DB level" do
    workout = create(:workout)
    create(:workout_check_in, workout: workout, status: "in_progress")

    expect do
      create(:workout_check_in, workout: workout, status: "in_progress")
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows a new in-progress check-in once the previous one is completed" do
    workout = create(:workout)
    create(:workout_check_in, :completed, workout: workout)

    expect { create(:workout_check_in, workout: workout, status: "in_progress") }.not_to raise_error
  end

  describe "#exercises_total / #exercises_completed_count" do
    it "counts the workout's live exercises and this check-in's completed ones" do
      workout = create(:workout)
      create_list(:exercise, 3, workout: workout)
      check_in = create(:workout_check_in, workout: workout)
      create(:exercise_check_in, workout_check_in: check_in, exercise: workout.exercises.first)

      expect(check_in.exercises_total).to eq(3)
      expect(check_in.exercises_completed_count).to eq(1)
    end
  end

  describe "#finish!" do
    it "marks the check-in completed and stamps completed_at" do
      check_in = create(:workout_check_in)
      check_in.finish!
      expect(check_in.status).to eq("completed")
      expect(check_in.completed_at).to be_present
    end
  end

  describe "#maybe_auto_finish!" do
    it "does nothing while exercises remain unchecked" do
      workout = create(:workout)
      create_list(:exercise, 2, workout: workout)
      check_in = create(:workout_check_in, workout: workout)
      create(:exercise_check_in, workout_check_in: check_in, exercise: workout.exercises.first)

      check_in.maybe_auto_finish!

      expect(check_in.reload.status).to eq("in_progress")
    end

    it "finishes the check-in once every exercise is checked" do
      workout = create(:workout)
      create_list(:exercise, 2, workout: workout)
      check_in = create(:workout_check_in, workout: workout)
      workout.exercises.each { |ex| create(:exercise_check_in, workout_check_in: check_in, exercise: ex) }

      check_in.maybe_auto_finish!

      expect(check_in.reload.status).to eq("completed")
    end

    it "does not touch an already-completed check-in" do
      check_in = create(:workout_check_in, :completed)
      completed_at = check_in.completed_at

      check_in.maybe_auto_finish!

      expect(check_in.reload.completed_at).to eq(completed_at)
    end
  end

  describe "#pse" do
    it "accepts values within 1..10" do
      expect(build(:workout_check_in, pse: 1)).to be_valid
      expect(build(:workout_check_in, pse: 10)).to be_valid
    end

    it "rejects values outside 1..10" do
      expect(build(:workout_check_in, pse: 0)).not_to be_valid
      expect(build(:workout_check_in, pse: 11)).not_to be_valid
    end

    it "allows nil (not yet captured)" do
      expect(build(:workout_check_in, pse: nil)).to be_valid
    end
  end

  describe "#mutually_confirmed?" do
    it "is false when neither side has confirmed" do
      expect(create(:workout_check_in).mutually_confirmed?).to be false
    end

    it "is false when only one side has confirmed" do
      expect(create(:workout_check_in, :student_performed).mutually_confirmed?).to be false
      expect(create(:workout_check_in, :personal_performed).mutually_confirmed?).to be false
    end

    it "is true only when both sides have confirmed" do
      expect(create(:workout_check_in, :mutually_confirmed).mutually_confirmed?).to be true
    end
  end

  describe "#confirm_as_student!" do
    it "stamps student_confirmed_at when not yet confirmed" do
      check_in = create(:workout_check_in, :personal_performed)
      check_in.confirm_as_student!
      expect(check_in.reload.student_confirmed_at).to be_present
    end

    it "is idempotent — does not overwrite an already-set timestamp" do
      check_in = create(:workout_check_in, :mutually_confirmed)
      original = check_in.student_confirmed_at

      check_in.confirm_as_student!

      expect(check_in.reload.student_confirmed_at).to eq(original)
    end
  end

  describe "#confirm_as_personal!" do
    it "stamps personal_confirmed_at when not yet confirmed" do
      check_in = create(:workout_check_in, :student_performed)
      check_in.confirm_as_personal!
      expect(check_in.reload.personal_confirmed_at).to be_present
    end

    it "is idempotent — does not overwrite an already-set timestamp" do
      check_in = create(:workout_check_in, :mutually_confirmed)
      original = check_in.personal_confirmed_at

      check_in.confirm_as_personal!

      expect(check_in.reload.personal_confirmed_at).to eq(original)
    end
  end

  describe "linking to a schedule session" do
    let(:trainer) { create(:trainer) }
    let(:student) { create(:student, trainer: trainer) }
    let(:workout) { create(:workout, student: student) }

    it "links to today's planned session once the check-in is completed and personal-confirmed" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = create(:workout_check_in, :personal_performed, workout: workout, status: "in_progress")

      check_in.finish!

      expect(session.reload.status).to eq("done")
      expect(session.workout_check_in_id).to eq(check_in.id)
    end

    it "does not link while only the student side is confirmed" do
      create(:schedule_session, student: student, trainer: trainer,
                                 status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = create(:workout_check_in, :student_performed, workout: workout, status: "in_progress")

      check_in.finish!

      expect(ScheduleSession.where.not(workout_check_in_id: nil)).to be_empty
    end

    it "links once the personal explicitly confirms after the student already finished it" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = create(:workout_check_in, :completed, :student_performed, workout: workout)

      check_in.confirm_as_personal!

      expect(session.reload.status).to eq("done")
      expect(session.workout_check_in_id).to eq(check_in.id)
    end

    it "does not re-trigger or duplicate the link on an unrelated later update (e.g. PSE)" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: Time.zone.now.change(hour: 7))
      check_in = create(:workout_check_in, :personal_performed, workout: workout, status: "in_progress")
      check_in.finish!
      linked_at = session.reload.updated_at

      check_in.update!(pse: 8)

      expect(session.reload.updated_at).to eq(linked_at)
      expect(ScheduleSession.count).to eq(1)
    end
  end

  describe "#mark_viewed!" do
    it "stamps viewed_at when not yet viewed" do
      check_in = create(:workout_check_in, :completed)
      check_in.mark_viewed!
      expect(check_in.reload.viewed_at).to be_present
    end

    it "is idempotent once already viewed" do
      check_in = create(:workout_check_in, :completed)
      check_in.mark_viewed!
      first_viewed_at = check_in.reload.viewed_at

      check_in.mark_viewed!

      expect(check_in.reload.viewed_at).to eq(first_viewed_at)
    end
  end
end
