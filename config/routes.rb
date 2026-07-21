Rails.application.routes.draw do
  # API docs (Swagger UI + raw OpenAPI file) are always available outside production;
  # in production they require an explicit opt-in to avoid exposing the API shape publicly.
  if Rails.env.local? || ActiveModel::Type::Boolean.new.cast(ENV["ENABLE_API_DOCS"])
    mount Rswag::Api::Engine => "/api-docs"
    mount Rswag::Ui::Engine => "/api-docs"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/login",    to: "auth#login"
      post "auth/register", to: "auth#register"
      post "auth/google",   to: "auth#google_auth"
      get   "auth/me",      to: "auth#me"
      patch "auth/me",      to: "auth#update_me"
      patch "auth/password", to: "auth#update_password"

      # Dashboard
      get "dashboard/kpis",       to: "dashboard#kpis"
      get "dashboard/activity",   to: "dashboard#activity"
      get "dashboard/attendance", to: "dashboard#attendance"

      # Completed workouts across the current trainer's/admin's portfolio,
      # for reviewing and giving feedback/reactions — not student-scoped.
      get "completed_check_ins", to: "completed_check_ins#index"

      # Agenda — calendário de treinos dinâmico. Recursos top-level (não
      # aninhados sob /students/:id/), filtrados por role dentro do
      # controller — mesmo formato de completed_check_ins acima.
      resources :schedule_sessions, only: %i[index update destroy]
      resources :schedule_plans, only: %i[create]

      # Chamado só por automação (workflow agendado), autenticado por token
      # compartilhado — não faz parte do contrato consumido pelo frontend.
      post "internal/cron/mark_missed_sessions", to: "cron#mark_missed_sessions"

      # Uploads — presigned S3 URLs
      post "uploads/presign", to: "uploads#presign"

      # Trainers (personals)
      resources :trainers, only: %i[index show create update destroy] do
        collection { get :search }
      end

      # Students
      resources :students, only: %i[index show create update destroy] do
        member { post :renew_cycle }

        # Attendance cycle history — closed cycles, archived on renew_cycle
        resources :attendance_cycles, only: %i[index]

        # Anamnesis
        resource :anamnesis, only: %i[show update], controller: "anamneses"

        # Structural assessment
        resource :structural_assessment, only: %i[show update], controller: "structural_assessments"

        # Biomechanical assessment
        resources :biomechanical_assessments, only: %i[index] do
          collection do
            get    :current
            post   :new_assessment
            put    :upload
            delete :remove_image
          end
        end

        # Evolution
        get    "evolution",             to: "evolution#index"
        get    "evolution/photos",      to: "evolution#photos"
        post   "evolution/photos",      to: "evolution#create_photo"
        delete "evolution/photos/:id",  to: "evolution#destroy_photo"

        # Bioimpedance measurements
        resources :bioimpedance_measurements, only: %i[index create destroy]

        # Workouts and exercises
        resources :workouts, only: %i[index create update destroy] do
          member do
            post :archive
            post :unarchive
          end
          collection { patch :reorder }
          resources :exercises, only: %i[create update destroy] do
            collection { patch :reorder }
          end

          # Check-ins — "Iniciar treino" / "Finalizar treino" / marcar exercícios
          resources :check_ins, only: %i[create destroy], controller: "workout_check_ins" do
            member do
              post :finish
              post :view
              post :confirm
              patch "exercises/:exercise_id", action: :toggle_exercise, as: :toggle_exercise
              patch "pse", action: :update_pse, as: :pse
            end
            collection { get :current }
            resources :feedbacks, only: %i[create update destroy], controller: "check_in_feedbacks"
          end
        end

        # Exams
        resources :exams, only: %i[index create destroy]

        # Check-in history (all workouts)
        get "check_ins", to: "workout_check_ins#index"
      end

      # Bioimpedance import (CSV)
      post "bioimpedance/import", to: "bioimpedance_imports#create"

      # Partners (showcase)
      resources :partners, only: %i[index create update destroy]

      # Push notifications — browser subscriptions, scoped to the current user
      post   "push_subscriptions", to: "push_subscriptions#create"
      delete "push_subscriptions", to: "push_subscriptions#destroy"
    end
  end
end
