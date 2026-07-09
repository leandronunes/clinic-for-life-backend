require "rails_helper"

RSpec.describe "Api::V1::Workouts", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  describe "GET /api/v1/students/:student_id/workouts" do
    it "lists workouts for the student" do
      create(:workout, student: student, status: "active")
      create(:workout, :archived, student: student)
      get "/api/v1/students/#{student.id}/workouts", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(2)
    end

    it "filters by status" do
      create(:workout, student: student, status: "active")
      create(:workout, :archived, student: student)
      get "/api/v1/students/#{student.id}/workouts", params: { status: "active" },
          headers: auth_headers(personal)
      expect(json_body["data"].map { |w| w["status"] }).to all(eq("active"))
    end
  end

  describe "POST /api/v1/students/:student_id/workouts" do
    it "creates a workout with nested exercises" do
      params = {
        title: "Push Day", focus: "Push", status: "active",
        exercises: [ { name: "Bench Press", sets: 4, reps: "8-10", rest_seconds: 90,
                       muscle_group: "Chest" } ]
      }
      expect do
        post "/api/v1/students/#{student.id}/workouts", params: params, headers: auth_headers(personal)
      end.to change(Workout, :count).by(1).and change(Exercise, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "auto-assigns sequential positions for new workouts" do
      create(:workout, student: student, status: "active", position: 1)
      post "/api/v1/students/#{student.id}/workouts",
           params: { title: "Segundo Treino", focus: "Pull" }, headers: auth_headers(personal)
      expect(json_body["data"]["position"]).to eq(2)
    end

    it "allows multiple active workouts to coexist" do
      old = create(:workout, student: student, status: "active")
      post "/api/v1/students/#{student.id}/workouts",
           params: { title: "New Active", status: "active" }, headers: auth_headers(personal)

      expect(old.reload.status).to eq("active")
      expect(student.workouts.active.count).to eq(2)
    end

    it "forbids a student from creating workouts" do
      post "/api/v1/students/#{student.id}/workouts",
           params: { title: "X" }, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "enqueues a push notification job when the student has a linked user" do
      student_user
      params = { title: "Push Day", focus: "Push", status: "active" }
      expect do
        post "/api/v1/students/#{student.id}/workouts", params: params, headers: auth_headers(personal)
      end.to have_enqueued_job(PushNotificationJob)
    end

    it "does not enqueue a push notification when the student has no linked user" do
      params = { title: "Push Day", focus: "Push", status: "active" }
      expect do
        post "/api/v1/students/#{student.id}/workouts", params: params, headers: auth_headers(personal)
      end.not_to have_enqueued_job(PushNotificationJob)
    end

    it "does not enqueue a push notification when the workout is created as archived" do
      student_user
      params = { title: "Push Day", focus: "Push", status: "archived" }
      expect do
        post "/api/v1/students/#{student.id}/workouts", params: params, headers: auth_headers(personal)
      end.not_to have_enqueued_job(PushNotificationJob)
    end
  end

  describe "PATCH /api/v1/students/:student_id/workouts/:id" do
    it "re-activates an archived workout without affecting other active workouts" do
      active = create(:workout, student: student, status: "active")
      archived = create(:workout, :archived, student: student)

      patch "/api/v1/students/#{student.id}/workouts/#{archived.id}",
            params: { status: "active" }, headers: auth_headers(personal)

      expect(archived.reload.status).to eq("active")
      expect(active.reload.status).to eq("active")
    end
  end

  describe "DELETE /api/v1/students/:student_id/workouts/:id" do
    it "removes the workout and its exercises" do
      workout = create(:workout, student: student, status: "active")
      create_list(:exercise, 2, workout: workout)

      expect do
        delete "/api/v1/students/#{student.id}/workouts/#{workout.id}",
               headers: auth_headers(personal)
      end.to change(Workout, :count).by(-1).and change(Exercise, :count).by(-2)

      expect(response).to have_http_status(:no_content)
    end

    it "forbids a student from deleting a workout" do
      workout = create(:workout, student: student, status: "active")
      delete "/api/v1/students/#{student.id}/workouts/#{workout.id}",
             headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
      expect(Workout.exists?(workout.id)).to be(true)
    end

    it "closes the position gap left behind for the remaining workouts" do
      w1 = create(:workout, student: student, status: "active", position: 1)
      w2 = create(:workout, student: student, status: "active", position: 2)
      w3 = create(:workout, student: student, status: "active", position: 3)

      delete "/api/v1/students/#{student.id}/workouts/#{w2.id}", headers: auth_headers(personal)

      expect(w1.reload.position).to eq(1)
      expect(w3.reload.position).to eq(2)
    end

    it "does not renumber workouts from the other status group" do
      active = create(:workout, student: student, status: "active", position: 1)
      archived = create(:workout, :archived, student: student, position: 5)

      delete "/api/v1/students/#{student.id}/workouts/#{active.id}", headers: auth_headers(personal)

      expect(archived.reload.position).to eq(5)
    end

    it "does not renumber another student's workouts" do
      outsider = create(:workout, status: "active", position: 3)
      workout = create(:workout, student: student, status: "active", position: 1)

      delete "/api/v1/students/#{student.id}/workouts/#{workout.id}", headers: auth_headers(personal)

      expect(outsider.reload.position).to eq(3)
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:id/archive" do
    it "archives the workout" do
      workout = create(:workout, student: student, status: "active")
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/archive",
           headers: auth_headers(personal)
      expect(workout.reload.status).to eq("archived")
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:id/unarchive" do
    it "reactivates an archived workout" do
      workout = create(:workout, :archived, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/unarchive",
           headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(workout.reload.status).to eq("active")
      expect(workout.reload.archived_at).to be_nil
    end

    it "returns the updated workout in the response" do
      workout = create(:workout, :archived, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/unarchive",
           headers: auth_headers(personal)

      expect(json_body["data"]["status"]).to eq("active")
    end

    it "returns 422 when the workout is already active" do
      workout = create(:workout, student: student, status: "active")
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/unarchive",
           headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids a student from unarchiving" do
      workout = create(:workout, :archived, student: student)
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/unarchive",
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/students/:student_id/workouts/reorder" do
    it "reassigns positions according to the given order" do
      w1 = create(:workout, student: student, status: "active", position: 1)
      w2 = create(:workout, student: student, status: "active", position: 2)
      w3 = create(:workout, student: student, status: "active", position: 3)

      patch "/api/v1/students/#{student.id}/workouts/reorder",
            params: { ordered_ids: [ w3.id, w1.id, w2.id ] },
            headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(w3.reload.position).to eq(1)
      expect(w1.reload.position).to eq(2)
      expect(w2.reload.position).to eq(3)
    end

    it "returns the full workout list in the new order" do
      w1 = create(:workout, student: student, status: "active", position: 1)
      w2 = create(:workout, student: student, status: "active", position: 2)

      patch "/api/v1/students/#{student.id}/workouts/reorder",
            params: { ordered_ids: [ w2.id, w1.id ] },
            headers: auth_headers(personal)

      ids = json_body["data"].map { |w| w["id"].to_i }
      expect(ids.first).to eq(w2.id)
    end

    it "does not affect workouts from other students" do
      outsider = create(:workout, status: "active", position: 1)
      w1 = create(:workout, student: student, status: "active", position: 1)
      w2 = create(:workout, student: student, status: "active", position: 2)

      patch "/api/v1/students/#{student.id}/workouts/reorder",
            params: { ordered_ids: [ outsider.id, w1.id, w2.id ] },
            headers: auth_headers(personal)

      expect(outsider.reload.position).to eq(1)
    end

    it "forbids students from reordering" do
      patch "/api/v1/students/#{student.id}/workouts/reorder",
            params: { ordered_ids: [] },
            headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
