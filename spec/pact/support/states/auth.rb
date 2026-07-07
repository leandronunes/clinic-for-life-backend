module PactStates
  module Auth
    LOGIN_EMAIL = "pact.login@forlife.app".freeze
    LOGIN_PASSWORD = "Str0ng@Pass1".freeze
    EXISTING_EMAIL = "pact.existing@forlife.app".freeze
    NEW_EMAIL = "pact.newaccount@forlife.app".freeze
    GOOGLE_LINKED_EMAIL = "pact.google.linked@forlife.app".freeze
    GOOGLE_NEW_EMAIL = "pact.google.new@forlife.app".freeze

    def self.definitions
      proc do
        provider_state "a user with valid credentials exists" do
          set_up do
            clean_database!
            FactoryBot.create(:user, email: PactStates::Auth::LOGIN_EMAIL,
                                     password: PactStates::Auth::LOGIN_PASSWORD)
          end
        end

        provider_state "no account exists for the given email" do
          set_up { clean_database! }
        end

        provider_state "no account is registered with this email" do
          set_up { clean_database! }
        end

        provider_state "an account is already registered with this email" do
          set_up do
            clean_database!
            FactoryBot.create(:user, email: PactStates::Auth::EXISTING_EMAIL)
          end
        end

        provider_state "a user already exists for this google account" do
          set_up do
            clean_database!
            FactoryBot.create(:user, email: PactStates::Auth::GOOGLE_LINKED_EMAIL)
            GoogleAuthService.define_singleton_method(:fetch_userinfo) do |_token|
              { "email" => PactStates::Auth::GOOGLE_LINKED_EMAIL, "name" => "Pact Google User" }
            end
          end
        end

        provider_state "no user exists for this google account yet" do
          set_up do
            clean_database!
            GoogleAuthService.define_singleton_method(:fetch_userinfo) do |_token|
              { "email" => PactStates::Auth::GOOGLE_NEW_EMAIL, "name" => "Pact Google User" }
            end
          end
        end

        provider_state "the google access token is invalid" do
          set_up do
            clean_database!
            GoogleAuthService.define_singleton_method(:fetch_userinfo) { |_token| nil }
          end
        end

        provider_state "an authenticated user requests their own profile" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end
      end
    end
  end
end
