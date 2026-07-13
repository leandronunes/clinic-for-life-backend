require "rails_helper"

RSpec.describe MynutriPdfParser do
  describe ".pdf_format?" do
    it "returns true for content starting with the PDF signature" do
      expect(described_class.pdf_format?(mynutri_pdf)).to be true
    end

    it "returns false for non-PDF content" do
      expect(described_class.pdf_format?("data,Peso(kg)\n20260602,90.0\n")).to be false
    end
  end

  describe ".parse" do
    it "extracts a single measurement from a valid mynutri/InBody report" do
      rows = described_class.parse(mynutri_pdf)

      expect(rows.size).to eq(1)
      row = rows.first
      expect(row.measured_on).to eq(Date.new(2026, 5, 15))
      expect(row.weight_kg).to eq(BigDecimal("54.4"))
      expect(row.muscle_mass_kg).to eq(BigDecimal("24.20"))
      expect(row.fat_percentage).to eq(BigDecimal("20"))
      expect(row.bmi).to eq(BigDecimal("22.40"))
      expect(row.visceral_fat).to eq(BigDecimal("3"))
    end

    it "returns the same ParsedRow struct type used by InbodyCsvParser" do
      row = described_class.parse(mynutri_pdf).first

      expect(row).to be_a(InbodyCsvParser::ParsedRow)
    end

    it "returns nil when the PDF has no recognizable bioimpedance fields" do
      expect(described_class.parse(non_inbody_pdf)).to be_nil
    end

    it "returns nil when the weight is missing" do
      pdf = mynutri_pdf(weight: "")
      expect(described_class.parse(pdf)).to be_nil
    end

    it "returns nil for malformed PDF bytes" do
      expect(described_class.parse("%PDF-1.4\nnot really a pdf")).to be_nil
    end
  end
end
