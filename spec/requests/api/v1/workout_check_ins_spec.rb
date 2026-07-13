require "rails_helper"

RSpec.describe "Api::V1::WorkoutCheckIns", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:trainer_user) { personal }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:workout) { create(:workout, student: student, status: "active") }

  describe "GET /api/v1/students/:student_id/workouts/:workout_id/check_ins/current" do
    it "returns null when there is no in-progress check-in" do
      get "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/current",
          headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to be_nil
    end

    it "returns the in-progress check-in when one exists" do
      check_in = create(:workout_check_in, workout: workout, student: student)
      get "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/current",
          headers: auth_headers(student_user)

      expect(json_body["data"]["id"]).to eq(check_in.id.to_s)
    end

    it "does not return a completed check-in as current" do
      create(:workout_check_in, :completed, workout: workout, student: student)
      get "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/current",
          headers: auth_headers(student_user)

      expect(json_body["data"]).to be_nil
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:workout_id/check_ins" do
    it "starts a new check-in" do
      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins",
             headers: auth_headers(student_user)
      end.to change(WorkoutCheckIn, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["status"]).to eq("in_progress")
    end

    it "allows a personal to start a check-in on behalf of their own student" do
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins",
           headers: auth_headers(personal)

      expect(response).to have_http_status(:created)
    end

    it "forbids a personal outside the student's portfolio" do
      other_personal = create(:user, :personal)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins",
           headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 for an archived workout" do
      archived = create(:workout, :archived, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{archived.id}/check_ins",
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when a check-in is already in progress" do
      create(:workout_check_in, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins",
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to match(/já existe/i)
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/finish" do
    it "finishes the check-in, completed or not" do
      check_in = create(:workout_check_in, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/finish",
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(check_in.reload.status).to eq("completed")
    end

    it "returns 422 when the check-in is already finished" do
      check_in = create(:workout_check_in, :completed, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/finish",
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not enqueue a push notification when no exercises were completed" do
      trainer_user
      check_in = create(:workout_check_in, workout: workout, student: student)
      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/finish",
             headers: auth_headers(student_user)
      end.not_to have_enqueued_job(PushNotificationJob)
    end

    it "enqueues a push notification to the trainer when at least one exercise was completed" do
      trainer_user
      exercise = create(:exercise, workout: workout)
      check_in = create(:workout_check_in, workout: workout, student: student)
      create(:exercise_check_in, workout_check_in: check_in, exercise: exercise)

      expect do
        post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/finish",
             headers: auth_headers(student_user)
      end.to have_enqueued_job(PushNotificationJob).with(
        trainer_user.id,
        hash_including(url: "/alunos/#{student.id}")
      )
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:workout_id/check_ins/:id/view" do
    it "stamps viewed_at on a completed check-in" do
      check_in = create(:workout_check_in, :completed, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/view",
           headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["viewed_at"]).to be_present
      expect(check_in.reload.viewed_at).to be_present
    end

    it "is idempotent when called twice" do
      check_in = create(:workout_check_in, :completed, workout: workout, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/view",
           headers: auth_headers(personal)
      first_viewed_at = check_in.reload.viewed_at

      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/view",
           headers: auth_headers(personal)

      expect(check_in.reload.viewed_at).to eq(first_viewed_at)
    end

    it "forbids a personal outside the student's portfolio" do
      check_in = create(:workout_check_in, :completed, workout: workout, student: student)
      other_personal = create(:user, :personal)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}/view",
           headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH .../check_ins/:id/exercises/:exercise_id" do
    let!(:exercise_a) { create(:exercise, workout: workout) }
    let!(:exercise_b) { create(:exercise, workout: workout) }
    let(:check_in) { create(:workout_check_in, workout: workout, student: student) }

    def toggle(exercise, completed:)
      patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/check_ins/#{check_in.id}" \
            "/exercises/#{exercise.id}",
            params: { completed: completed }, headers: auth_headers(student_user)
    end

    it "marks an exercise as completed" do
      toggle(exercise_a, completed: true)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["completed_exercise_ids"]).to contain_exactly(exercise_a.id.to_s)
      expect(json_body["data"]["exercises_completed"]).to eq(1)
    end

    it "unmarks a previously completed exercise" do
      toggle(exercise_a, completed: true)
      toggle(exercise_a, completed: false)

      expect(json_body["data"]["completed_exercise_ids"]).to be_empty
    end

    it "is idempotent when marking the same exercise twice" do
      toggle(exercise_a, completed: true)
      expect { toggle(exercise_a, completed: true) }.not_to change(ExerciseCheckIn, :count)
    end

    it "auto-finishes the check-in once every exercise is marked" do
      toggle(exercise_a, completed: true)
      toggle(exercise_b, completed: true)

      expect(json_body["data"]["status"]).to eq("completed")
      expect(check_in.reload.status).to eq("completed")
    end

    it "enqueues a push notification to the trainer on auto-finish" do
      trainer_user
      toggle(exercise_a, completed: true)

      expect { toggle(exercise_b, completed: true) }.to have_enqueued_job(PushNotificationJob).with(
        trainer_user.id,
        hash_including(url: "/alunos/#{student.id}")
      )
    end

    it "returns 422 once the check-in has been finished" do
      check_in.finish!
      toggle(exercise_a, completed: true)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 for an exercise that does not belong to the workout" do
      other_exercise = create(:exercise)
      toggle(other_exercise, completed: true)

      expect(response).to have_http_status(:not_found)
    end
  end
end
