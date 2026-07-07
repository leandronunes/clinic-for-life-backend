module PactStates
  module Uploads
    STUDENT_ID = 2201

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} exists for uploads" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: student.trainer))

            # Stubbed the same way spec/requests/api/v1/uploads_spec.rb does —
            # #presign needs S3_BUCKET/real AWS creds otherwise, which CI
            # doesn't (and shouldn't need to) provide just to verify this
            # contract. Redefining the instance method directly (rather than
            # RSpec::Mocks) because this runs outside a normal example.
            S3Presigner.define_method(:presign) do |content_type:, context:, student_id: nil|
              {
                upload_url: "https://clinic-for-life.s3.us-west-2.amazonaws.com/uploads/students/#{student_id}/#{context}/uuid.jpg?X-Amz-Signature=abc",
                public_url: "https://clinic-for-life.s3.us-west-2.amazonaws.com/uploads/students/#{student_id}/#{context}/uuid.jpg"
              }
            end
          end
        end
      end
    end
  end
end
