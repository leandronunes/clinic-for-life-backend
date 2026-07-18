require "rails_helper"

RSpec.describe ScheduleExpansionService do
  let(:slot_class) { Struct.new(:weekday, :time, :duration_minutes) }

  describe ".occurrences" do
    it "expands weekday slots between two dates inclusive" do
      # 2026-07-06 é segunda-feira
      slots = [
        slot_class.new(1, "07:00", 60),
        slot_class.new(3, "18:30", 45)
      ]

      out = described_class.occurrences(slots: slots, starts_on: "2026-07-06", ends_on: "2026-07-19")

      # Duas semanas: 2 seg + 2 qua = 4 ocorrências
      expect(out.size).to eq(4)
      first = out.first[:starts_at]
      expect(first.hour).to eq(7)
      expect(first.wday).to eq(1)
    end

    it "returns [] when starts_on > ends_on" do
      slots = [ slot_class.new(1, "07:00", 60) ]
      out = described_class.occurrences(slots: slots, starts_on: "2026-07-20", ends_on: "2026-07-01")
      expect(out).to eq([])
    end

    it "returns [] when no slot matches any weekday in range" do
      slots = [ slot_class.new(1, "07:00", 60) ]
      # 2026-07-07 a 2026-07-08 (terça a quarta) não contém nenhuma segunda
      out = described_class.occurrences(slots: slots, starts_on: "2026-07-07", ends_on: "2026-07-08")
      expect(out).to eq([])
    end

    it "generates the correct instant in America/Sao_Paulo (UTC-3)" do
      slots = [ slot_class.new(1, "07:00", 60) ]
      out = described_class.occurrences(slots: slots, starts_on: "2026-07-06", ends_on: "2026-07-06")
      expect(out.first[:starts_at].utc.hour).to eq(10) # 07:00 -03:00 == 10:00 UTC
    end
  end

  describe ".day_range" do
    it "returns the start and end of the given day in America/Sao_Paulo" do
      range = described_class.day_range("2026-07-06")
      expect(range.begin.hour).to eq(0)
      expect(range.begin.min).to eq(0)
      expect(range.end.hour).to eq(23)
      expect(range.end.min).to eq(59)
    end
  end
end
