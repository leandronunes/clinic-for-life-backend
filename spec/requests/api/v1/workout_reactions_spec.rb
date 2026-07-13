require "rails_helper"

RSpec.describe "Api::V1::WorkoutReactions", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:workout) { create(:workout, student: student) }
  let(:check_in) { create(:workout_check_in, :completed, workout: workout, student: student) }

  describe "POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:check_in_id/reaction" do
    it "creates a reaction as the current user" do
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
           params: { emoji: "🔥" }, headers: auth_headers(personal)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["emoji"]).to eq("🔥")
      expect(json_body["data"]["author_name"]).to eq(personal.name)
    end

    it "replaces the current user's existing reaction instead of duplicating it" do
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
           params: { emoji: "🔥" }, headers: auth_headers(personal)

      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
             params: { emoji: "💪" }, headers: auth_headers(personal)
      end.not_to change(WorkoutReaction, :count)

      expect(json_body["data"]["emoji"]).to eq("💪")
    end

    it "returns 422 when the check-in is still in progress" do
      in_progress = create(:workout_check_in, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{in_progress.id}/reaction",
           params: { emoji: "🔥" }, headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids a personal outside the student's portfolio" do
      other_personal = create(:user, :personal)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
           params: { emoji: "🔥" }, headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a student from reacting, even to their own check-in" do
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
           params: { emoji: "🔥" }, headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "does not enqueue a push notification when the student has no linked user" do
      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
             params: { emoji: "🔥" }, headers: auth_headers(personal)
      end.not_to have_enqueued_job(PushNotificationJob)
    end

    it "enqueues a push notification to the student" do
      student_user
      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/reaction",
             params: { emoji: "🔥" }, headers: auth_headers(personal)
      end.to have_enqueued_job(PushNotificationJob).with(
        student_user.id,
        hash_including(title: "Seu personal reagiu ao seu treino!", url: "/aluno/assiduidade")
      )
    end
  end
end
