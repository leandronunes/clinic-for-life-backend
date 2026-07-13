require "prawn"

# Builds minimal synthetic PDFs shaped like InBody/mynutri body composition reports,
# so specs don't need to check a real report (with a real person's data) into the repo.
module MynutriPdfFixtures
  def mynutri_pdf(date: "15/05/2026", weight: "54.4", muscle: "24.20", fat_pct: "20", bmi: "22.40", visceral: "3")
    Prawn::Fonts::AFM.hide_m17n_warning = true

    doc = Prawn::Document.new
    doc.text "Aluno Teste       150cm        30 anos      Feminino     #{date} às 00:00"
    doc.text "A soma acima Peso (kg) #{weight} (43.4~58.8)"
    doc.text "Esquelética (kg) #{muscle}"
    doc.text "Percentual de Gordura #{fat_pct}"
    doc.text "Índice de Massa Corporal #{bmi}"
    doc.text "Nível de Gordura Visceral #{visceral} (1~9)"
    doc.render
  end

  def non_inbody_pdf
    Prawn::Fonts::AFM.hide_m17n_warning = true

    doc = Prawn::Document.new
    doc.text "This PDF has no bioimpedance data at all."
    doc.render
  end

  def pdf_upload(bytes, filename: "bio.pdf")
    file = Tempfile.new([ "bio", ".pdf" ], binmode: true)
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "application/pdf", true, original_filename: filename)
  end
end

RSpec.configure do |config|
  config.include MynutriPdfFixtures
end
