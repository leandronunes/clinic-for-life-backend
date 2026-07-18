require "rails_helper"

RSpec.describe "Api::V1::SchedulePlans", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:admin) { create(:user, :admin) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  def valid_payload(overrides = {})
    {
      student_id: student.id,
      starts_on: "2026-07-06",
      ends_on: "2026-07-19",
      notes: "Foco em hipertrofia",
      weekdays: [
        { weekday: 1, time: "07:00", duration_minutes: 60 },
        { weekday: 3, time: "18:30", duration_minutes: 45 }
      ]
    }.merge(overrides)
  end

  describe "POST /api/v1/schedule_plans" do
    it "creates the plan and expands it into sessions" do
      post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(personal)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["created"]).to eq(4) # 2 segundas + 2 quartas
      expect(json_body["data"]["sessions"].size).to eq(4)
      first = json_body["data"]["sessions"].first
      expect(first["student_id"]).to eq(student.id.to_s)
      expect(first["student_name"]).to eq(student.name)
      expect(first["trainer_id"]).to eq(trainer.id.to_s)
      expect(first["status"]).to eq("planned")
      expect(first["plan_id"]).to be_present
    end

    it "persists the sessions in the database" do
      expect do
        post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(personal)
      end.to change(ScheduleSession, :count).by(4)
    end

    it "allows an admin to create a plan for any student" do
      post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
    end

    it "forbids a student from creating a plan" do
      post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a personal from creating a plan for a student outside their portfolio" do
      other_personal = create(:user, :personal)

      post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when no weekday is selected" do
      # as: :json — um array vazio via rack-test com encoding padrão
      # (multipart/form) chega como [""] em vez de []; a request real do
      # frontend sempre é JSON, então é isso que reflete o contrato de verdade.
      post "/api/v1/schedule_plans", params: valid_payload(weekdays: []), headers: auth_headers(personal),
                                      as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when ends_on is before starts_on" do
      post "/api/v1/schedule_plans", params: valid_payload(starts_on: "2026-07-20", ends_on: "2026-07-01"),
                                      headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when the range exceeds 366 days" do
      post "/api/v1/schedule_plans", params: valid_payload(starts_on: "2026-01-01", ends_on: "2028-01-01"),
                                      headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a duration outside 15..240" do
      post "/api/v1/schedule_plans",
           params: valid_payload(weekdays: [ { weekday: 1, time: "07:00", duration_minutes: 5 } ]),
           headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 for a student that does not exist" do
      post "/api/v1/schedule_plans", params: valid_payload(student_id: 999_999), headers: auth_headers(personal)

      expect(response).to have_http_status(:not_found)
    end

    it "does not create any sessions when the plan is invalid" do
      expect do
        post "/api/v1/schedule_plans", params: valid_payload(weekdays: []), headers: auth_headers(personal),
                                        as: :json
      end.not_to change(ScheduleSession, :count)
    end

    it "records an audit log on creation" do
      expect do
        post "/api/v1/schedule_plans", params: valid_payload, headers: auth_headers(personal)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("schedule_plan.create")
    end
  end
end
