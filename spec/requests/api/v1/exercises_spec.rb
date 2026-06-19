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

    context "when video_url changes from an S3 URL" do
      let(:s3_url) { "https://clinic-bucket.s3.us-east-1.amazonaws.com/uploads/old.mp4" }
      let(:new_s3_url) { "https://clinic-bucket.s3.us-east-1.amazonaws.com/uploads/new.mp4" }
      let(:exercise) { create(:exercise, workout: workout, video_url: s3_url) }

      it "calls S3Presigner to delete the old video" do
        presigner = instance_double(S3Presigner)
        allow(S3Presigner).to receive(:new).and_return(presigner)
        allow(presigner).to receive(:delete)

        patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
              params: { video_url: new_s3_url }, headers: auth_headers(personal)

        expect(presigner).to have_received(:delete).with(public_url: s3_url)
      end

      it "returns 200 even when S3 deletion raises an error" do
        allow_any_instance_of(S3Presigner).to receive(:delete)
          .and_raise(Aws::S3::Errors::NoSuchKey.new({}, ""))

        patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
              params: { video_url: new_s3_url }, headers: auth_headers(personal)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when video_url does not change" do
      it "does not call S3Presigner" do
        exercise = create(:exercise, workout: workout,
                          video_url: "https://clinic-bucket.s3.us-east-1.amazonaws.com/old.mp4")
        expect(S3Presigner).not_to receive(:new)

        patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
              params: { load_kg: 50 }, headers: auth_headers(personal)
      end
    end

    context "when old video_url is a YouTube URL" do
      it "does not call S3Presigner" do
        exercise = create(:exercise, workout: workout,
                          video_url: "https://www.youtube.com/embed/abc123")
        expect(S3Presigner).not_to receive(:new)

        patch "/api/v1/students/#{student.id}/workouts/#{workout.id}/exercises/#{exercise.id}",
              params: { video_url: "https://clinic-bucket.s3.us-east-1.amazonaws.com/new.mp4" },
              headers: auth_headers(personal)
      end
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
