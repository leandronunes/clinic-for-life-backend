require "rails_helper"

RSpec.describe UserSerializer do
  it "serializes a user with string ids" do
    student = create(:student)
    user = create(:user, :student_account, student: student, avatar_url: "https://x/a.png")
    json = described_class.new(user).as_json

    expect(json[:id]).to eq(user.id.to_s)
    expect(json[:name]).to eq(user.name)
    expect(json[:email]).to eq(user.email)
    expect(json[:role]).to eq("student")
    expect(json[:student_id]).to eq(student.id.to_s)
    expect(json[:trainer_id]).to be_nil
    expect(json[:mfa_enabled]).to be(false)
  end
end

RSpec.describe TrainerSerializer do
  it "serializes a trainer including students_count" do
    trainer = create(:trainer)
    create_list(:student, 2, trainer: trainer)
    json = described_class.new(trainer).as_json

    expect(json[:id]).to eq(trainer.id.to_s)
    expect(json[:cpf]).to eq(trainer.cpf)
    expect(json[:students_count]).to eq(2)
  end
end

RSpec.describe StudentSerializer do
  it "serializes a student including the trainer name" do
    trainer = create(:trainer, name: "Rafael")
    student = create(:student, trainer: trainer)
    json = described_class.new(student).as_json

    expect(json[:id]).to eq(student.id.to_s)
    expect(json[:trainer_id]).to eq(trainer.id.to_s)
    expect(json[:trainer_name]).to eq("Rafael")
  end
end

RSpec.describe WorkoutSerializer do
  it "serializes a workout with nested exercises" do
    workout = create(:workout)
    create(:exercise, workout: workout, name: "Bench Press")
    json = described_class.new(workout).as_json

    expect(json[:id]).to eq(workout.id.to_s)
    expect(json[:status]).to eq("active")
    expect(json[:exercises].first[:name]).to eq("Bench Press")
  end
end

RSpec.describe ExerciseSerializer do
  it "serializes an exercise with numeric load" do
    exercise = create(:exercise, load_kg: 42.5)
    json = described_class.new(exercise).as_json

    expect(json[:id]).to eq(exercise.id.to_s)
    expect(json[:load_kg]).to eq(42.5)
    expect(json[:sets]).to eq(exercise.sets)
  end
end

RSpec.describe PartnerSerializer do
  it "serializes a partner" do
    partner = create(:partner)
    json = described_class.new(partner).as_json

    expect(json[:id]).to eq(partner.id.to_s)
    expect(json[:category]).to eq(partner.category)
    expect(json[:coupon]).to eq(partner.coupon)
  end
end

RSpec.describe BioimpedanceMeasurementSerializer do
  it "serializes a measurement with floats and ISO date" do
    measurement = create(:bioimpedance_measurement, weight_kg: 70.5, measured_on: "2025-09-01")
    json = described_class.new(measurement).as_json

    expect(json[:id]).to eq(measurement.id.to_s)
    expect(json[:weight_kg]).to eq(70.5)
    expect(json[:measured_on]).to eq("2025-09-01")
  end
end

RSpec.describe EvolutionPhotoSerializer do
  it "serializes an evolution photo" do
    photo = create(:evolution_photo, taken_on: "2025-09-01")
    json = described_class.new(photo).as_json

    expect(json[:id]).to eq(photo.id.to_s)
    expect(json[:taken_on]).to eq("2025-09-01")
    expect(json[:image_url]).to eq(photo.image_url)
  end
end

RSpec.describe BiomechanicalAssessmentSerializer do
  it "serializes an assessment with the images map" do
    assessment = create(:biomechanical_assessment)
    create(:biomechanical_image, biomechanical_assessment: assessment, slot: "frontal")
    json = described_class.new(assessment).as_json

    expect(json[:id]).to eq(assessment.id.to_s)
    expect(json[:images]).to have_key("frontal")
  end
end

RSpec.describe StructuralAssessmentSerializer do
  it "serializes all boolean items" do
    assessment = create(:structural_assessment, scoliosis: true)
    json = described_class.new(assessment).as_json

    expect(json["scoliosis"]).to be(true)
    expect(json["knee_valgus"]).to be(false)
    expect(json.keys.size).to eq(StructuralAssessment::ITEMS.size)
  end
end

RSpec.describe AnamnesisSerializer do
  it "serializes fields plus external professionals" do
    anamnesis = create(:anamnesis, objectives: "Gain muscle")
    create(:external_professional, anamnesis: anamnesis, name: "Dr. House")
    json = described_class.new(anamnesis).as_json

    expect(json[:id]).to eq(anamnesis.id.to_s)
    expect(json["objectives"]).to eq("Gain muscle")
    expect(json[:external_professionals].first[:name]).to eq("Dr. House")
  end
end

RSpec.describe ExamSerializer do
  it "serializes an exam" do
    exam = create(:exam)
    json = described_class.new(exam).as_json

    expect(json[:id]).to eq(exam.id.to_s)
    expect(json[:name]).to eq(exam.name)
    expect(json[:content_type]).to eq("application/pdf")
  end
end
