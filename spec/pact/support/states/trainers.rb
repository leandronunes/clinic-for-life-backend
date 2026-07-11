module PactStates
  module Trainers
    SHOW_ID = 601
    UPDATE_ID = 602
    DELETE_ID = 603

    def self.definitions
      proc do
        provider_state "at least one trainer exists" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, name: "Ana Personal")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a trainer matching the search query exists" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, name: "Ana Personal", status: "active")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "at least one active trainer exists, alongside an inactive one" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, name: "Ana Personal", status: "active")
            FactoryBot.create(:trainer, name: "Marina Inativa", status: "inactive")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an active trainer matching the search query exists, alongside a blocked one" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, name: "Ana Personal", status: "active")
            FactoryBot.create(:trainer, name: "Ana Bloqueada", status: "blocked")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a trainer with id #{PactStates::Trainers::SHOW_ID} exists" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, id: PactStates::Trainers::SHOW_ID)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "no trainer exists with the given id" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an admin is authenticated for trainer management" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a personal is authenticated for trainer management" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :personal))
          end
        end

        provider_state "a trainer with id #{PactStates::Trainers::UPDATE_ID} exists" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, id: PactStates::Trainers::UPDATE_ID)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a trainer with id #{PactStates::Trainers::DELETE_ID} exists" do
          set_up do
            clean_database!
            FactoryBot.create(:trainer, id: PactStates::Trainers::DELETE_ID)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end
      end
    end
  end
end
