module Api
  module V1
    class TrainersController < BaseController
      before_action :require_admin_for_write, only: %i[create update destroy]

      # GET /api/v1/trainers?status=active or ?status=active,blocked
      def index
        trainers = filter_by_status(trainer_scope.order(:name))
        render_data(trainers.map { |trainer| TrainerSerializer.new(trainer).as_json },
                    meta: { total: trainers.size })
      end

      # GET /api/v1/trainers/search?query=&status=active
      def search
        query = params[:query].to_s.strip.downcase
        trainers = filter_by_status(trainer_scope)
        if query.present?
          trainers = trainers.where(
            "lower(name) LIKE :q OR lower(cref) LIKE :q OR lower(email) LIKE :q",
            q: "%#{query}%"
          )
        end
        trainers = trainers.order(:name).limit(8)
        render_data(trainers.map { |trainer| TrainerSerializer.new(trainer).as_json })
      end

      # GET /api/v1/trainers/:id
      def show
        trainer = Trainer.find(params[:id])
        authorize_trainer!(trainer)
        return if performed?

        render_data(TrainerSerializer.new(trainer).as_json)
      end

      # POST /api/v1/trainers
      def create
        trainer = Trainer.new(trainer_params)
        trainer.organization_id = current_user.organization_id
        trainer.approved_at = Time.current
        trainer.save!
        audit!("trainer.create", record: trainer)
        render_data(TrainerSerializer.new(trainer).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/trainers/:id
      def update
        trainer = Trainer.find(params[:id])
        authorize_organization!(trainer)
        return if performed?

        trainer.update!(trainer_params)
        audit!("trainer.update", record: trainer)
        render_data(TrainerSerializer.new(trainer).as_json)
      end

      # DELETE /api/v1/trainers/:id
      def destroy
        trainer = Trainer.find(params[:id])
        authorize_organization!(trainer)
        return if performed?

        audit!("trainer.destroy", record: trainer)
        trainer.destroy!
        head :no_content
      end

      private

      # index/search/show são abertos a qualquer papel autenticado (sempre
      # foram) — mas um personal só pode ENXERGAR o próprio registro de
      # trainer, enquanto os demais papéis veem qualquer trainer dentro da
      # própria organização. trainer_scope já codifica exatamente essa
      # política; reaproveitar em vez de duplicar o branch aqui.
      def authorize_trainer!(trainer)
        return if trainer_scope.exists?(id: trainer.id)

        render json: { error: "Forbidden" }, status: :forbidden
      end

      # Accepts a single status ("active") or a comma-separated list
      # ("active,blocked"). Absent/blank param means no filtering.
      def filter_by_status(scope)
        statuses = params[:status].to_s.split(",").map(&:strip).reject(&:blank?)
        statuses.present? ? scope.where(status: statuses) : scope
      end

      def trainer_params
        params.permit(:name, :cpf, :cref, :email, :phone, :status, :avatar_url)
      end

      def require_admin_for_write
        require_role!(:admin)
      end
    end
  end
end
