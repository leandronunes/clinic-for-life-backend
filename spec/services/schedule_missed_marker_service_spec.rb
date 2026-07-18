require "rails_helper"

RSpec.describe ScheduleMissedMarkerService do
  let(:trainer) { create(:trainer) }
  let(:student) { create(:student, trainer: trainer) }

  describe ".call" do
    it "marks a planned session whose end time has passed as missed" do
      session = create(:schedule_session, :planned_in_the_past, student: student, trainer: trainer)

      expect(described_class.call).to eq(1)
      expect(session.reload.status).to eq("missed")
    end

    it "does not touch a planned session still in the future" do
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: 1.day.from_now)

      expect(described_class.call).to eq(0)
      expect(session.reload.status).to eq("planned")
    end

    it "does not touch a planned session whose end time has not passed yet" do
      # começou há 10 minutos, dura 60 — ainda em andamento
      session = create(:schedule_session, student: student, trainer: trainer,
                                           status: "planned", starts_at: 10.minutes.ago, duration_minutes: 60)

      expect(described_class.call).to eq(0)
      expect(session.reload.status).to eq("planned")
    end

    %w[done canceled missed].each do |status|
      it "does not touch a session already in status '#{status}', even if its time has passed" do
        session = create(:schedule_session, student: student, trainer: trainer,
                                             status: status, starts_at: 2.hours.ago, duration_minutes: 30)

        described_class.call

        expect(session.reload.status).to eq(status)
      end
    end

    it "marks multiple qualifying sessions at once and returns the count" do
      create(:schedule_session, :planned_in_the_past, student: student, trainer: trainer)
      create(:schedule_session, :planned_in_the_past, student: student, trainer: trainer)
      create(:schedule_session, student: student, trainer: trainer, status: "planned", starts_at: 1.day.from_now)

      expect(described_class.call).to eq(2)
    end
  end
end
