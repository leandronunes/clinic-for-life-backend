require "rails_helper"

RSpec.describe "Api::V1::Exercises", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:workout) { create(:workout, student: student) }

  describe "POST .../exercises" do
    it "creates an exercise" do
      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises",
             params: { name: "Squat", sets: 4, reps: "10", rest_seconds: 90 },
             headers: auth_headers(personal)
      end.to change(Exercise, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(workout.exercises.find_by(name: "Squat")).to be_present
    end

    it "respects an explicitly provided position" do
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises",
           params: { name: "Deadlift", sets: 4, reps: "5", rest_seconds: 120, position: 3 },
           headers: auth_headers(personal)

      expect(workout.exercises.find_by(name: "Deadlift").position).to eq(3)
    end

    it "forbids a student from creating exercises" do
      student_user = create(:user, :student_account, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises",
           params: { name: "Squat", sets: 4, reps: "10", rest_seconds: 90 },
           headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH .../exercises/:id" do
    it "updates an exercise" do
      exercise = create(:exercise, workout: workout)
      patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
            params: { load_kg: 50 }, headers: auth_headers(personal)
      expect(exercise.reload.load_kg).to eq(50)
    end
  end

  describe "DELETE .../exercises/:id" do
    it "removes an exercise" do
      exercise = create(:exercise, workout: workout)
      expect do
        delete "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
               headers: auth_headers(personal)
      end.to change(Exercise, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
