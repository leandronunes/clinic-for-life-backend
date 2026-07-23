module PactStates
  module Students
    SHOW_ID = 501
    UPDATE_ID = 502
    DELETE_ID = 503
    FORBIDDEN_ID = 504
    TRAINER_ID = 10
    MIGRATION_STUDENT_ID = 6001
    MIGRATION_REQUEST_ID = 6002

    def self.definitions
      proc do
        provider_state "at least one student exists" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create_list(:student, 2, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "no students exist" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "only active students exist" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, trainer: trainer, status: "active")
            FactoryBot.create(:student, trainer: trainer, status: "inactive")
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{PactStates::Students::SHOW_ID} exists" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::SHOW_ID, trainer: trainer,
                                        health_plan: nil, emergency_contact: nil)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "no student exists with the given id" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{PactStates::Students::FORBIDDEN_ID} belongs to another trainer" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::FORBIDDEN_ID, trainer: other_trainer)
            requesting_trainer = FactoryBot.create(:trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: requesting_trainer))
          end
        end

        provider_state "an admin is authenticated" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization)
            FactoryBot.create(:trainer, id: PactStates::Students::TRAINER_ID, organization: organization)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: organization))
          end
        end

        provider_state "a student user is authenticated" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :student_account))
          end
        end

        provider_state "a student with id #{PactStates::Students::DELETE_ID} exists and a non-admin is authenticated" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::DELETE_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :student_account))
          end
        end

        provider_state "a student with id #{PactStates::Students::UPDATE_ID} exists" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::UPDATE_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{PactStates::Students::DELETE_ID} exists" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::DELETE_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with the e-mail duplicado@forlife.app already exists " \
                        "in the admin's own organization" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, email: "duplicado@forlife.app", trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with the e-mail outraorg@forlife.app exists in another organization" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, email: "outraorg@forlife.app", trainer: other_trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an admin is authenticated and a student with id #{PactStates::Students::MIGRATION_STUDENT_ID} " \
                        "exists in another organization" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: PactStates::Students::MIGRATION_STUDENT_ID,
                                        email: "convidado@forlife.app", trainer: other_trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a personal is authenticated" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :personal))
          end
        end

        provider_state "student #{PactStates::Students::MIGRATION_STUDENT_ID} has a pending migration request " \
                        "#{PactStates::Students::MIGRATION_REQUEST_ID}" do
          set_up do
            clean_database!
            source_trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: PactStates::Students::MIGRATION_STUDENT_ID,
                                                  trainer: source_trainer)
            requester = FactoryBot.create(:user, :admin)
            FactoryBot.create(:student_migration_request, id: PactStates::Students::MIGRATION_REQUEST_ID,
                                                          student: student, requested_by: requester,
                                                          source_organization: source_trainer.organization,
                                                          target_organization: requester.organization)
            PactStateContext.as(FactoryBot.create(:user, :student_account, student: student,
                                                                            organization: source_trainer.organization))
          end
        end
      end
    end
  end
end
