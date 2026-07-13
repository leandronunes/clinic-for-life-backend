require "rails_helper"

RSpec.describe "Api::V1::CheckInFeedbacks", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:admin) { create(:user, :admin) }
  let(:workout) { create(:workout, student: student) }
  let(:check_in) { create(:workout_check_in, :completed, workout: workout, student: student) }
  let(:base_path) { "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/feedbacks" }

  describe "POST .../feedbacks" do
    context "with a text message" do
      let(:valid_params) { { message: "Mandou muito bem no treino de hoje!" } }

      it "creates feedback tied to the check-in as the current user" do
        post base_path, params: valid_params, headers: auth_headers(personal)

        expect(response).to have_http_status(:created)
        expect(json_body["data"]["message"]).to eq("Mandou muito bem no treino de hoje!")
        expect(json_body["data"]["author_name"]).to eq(personal.name)
        expect(json_body["data"]["workout_check_in_id"]).to eq(check_in.id.to_s)
        expect(json_body["data"]["emoji"]).to be_nil
      end

      it "allows an admin to send feedback" do
        post base_path, params: valid_params, headers: auth_headers(admin)
        expect(response).to have_http_status(:created)
      end

      it "forbids a student from sending feedback" do
        post base_path, params: valid_params, headers: auth_headers(student_user)
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 422 when the check-in is still in progress" do
        in_progress = create(:workout_check_in, workout: workout, student: student)
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{in_progress.id}/feedbacks",
             params: valid_params, headers: auth_headers(personal)
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body["error"]).to match(/concluído/i)
      end
    end

    context "with an emoji reaction" do
      let(:valid_params) { { emoji: "💪" } }

      it "creates an emoji feedback" do
        post base_path, params: valid_params, headers: auth_headers(personal)

        expect(response).to have_http_status(:created)
        expect(json_body["data"]["emoji"]).to eq("💪")
        expect(json_body["data"]["message"]).to be_nil
      end
    end

    context "with both emoji and message" do
      it "creates a combined feedback" do
        post base_path, params: { emoji: "🔥", message: "Arrasei!" }, headers: auth_headers(personal)

        expect(response).to have_http_status(:created)
        expect(json_body["data"]["emoji"]).to eq("🔥")
        expect(json_body["data"]["message"]).to eq("Arrasei!")
      end
    end

    context "with neither emoji nor message" do
      it "returns 422" do
        post base_path, params: {}, headers: auth_headers(personal)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "push notifications" do
      it "does not enqueue a push notification when the student has no linked user" do
        expect do
          post base_path, params: { message: "Bom treino!" }, headers: auth_headers(personal)
        end.not_to have_enqueued_job(PushNotificationJob)
      end

      it "enqueues a push notification for text feedback" do
        student_user
        expect do
          post base_path, params: { message: "Bom treino!" }, headers: auth_headers(personal)
        end.to have_enqueued_job(PushNotificationJob).with(
          student_user.id,
          hash_including(title: "Feedback do seu Personal", url: "/aluno/assiduidade")
        )
      end

      it "enqueues a push notification for emoji reaction" do
        student_user
        expect do
          post base_path, params: { emoji: "💪" }, headers: auth_headers(personal)
        end.to have_enqueued_job(PushNotificationJob).with(
          student_user.id,
          hash_including(title: "Seu personal reagiu ao seu treino!", url: "/aluno/assiduidade")
        )
      end
    end
  end
end
