module Api
  module V1
    class OrganizationsController < BaseController
      # Público — usado pelo seletor "entrar numa organização existente" no
      # cadastro, antes mesmo da conta existir. Só id/name/domain, nada
      # sensível (sem contagem de membros, sem dados de trainers/students).
      skip_before_action :authenticate_request!, only: %i[index]
      before_action -> { require_role!(:admin) }, only: %i[update]

      # GET /api/v1/organizations
      #
      # Exclui organizações `solo: true` — são as organizações privadas
      # autogeradas para um personal que optou por atuar sozinho no
      # cadastro (ver AuthController#build_trainer_for_registration!), não
      # organizações reais que outra pessoa poderia querer entrar.
      def index
        organizations = Organization.where(solo: false).order(:name)
        render_data(organizations.map { |o| OrganizationSerializer.new(o).as_json })
      end

      # PATCH/PUT /api/v1/organizations/:id
      #
      # Admin só pode editar a própria organização (não há uma noção de
      # super-admin cross-tenant) — Organization não carrega organization_id
      # (ela É o tenant), então não dá pra reusar authorize_organization! do
      # OrganizationScoped, que compara essa coluna.
      def update
        organization = Organization.find(params[:id])
        unless organization.id == current_user.organization_id
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        organization.update!(organization_params)
        audit!("organization.update", record: organization)
        render_data(OrganizationSerializer.new(organization).as_json)
      end

      private

      def organization_params
        params.permit(:name, :domain)
      end
    end
  end
end
