module Api
  module V1
    class OrganizationsController < BaseController
      # Público — usado pelo seletor "entrar numa organização existente" no
      # cadastro, antes mesmo da conta existir. Só id/name/domain, nada
      # sensível (sem contagem de membros, sem dados de trainers/students).
      skip_before_action :authenticate_request!, only: %i[index]

      # GET /api/v1/organizations
      def index
        organizations = Organization.order(:name)
        render_data(organizations.map { |o| OrganizationSerializer.new(o).as_json })
      end
    end
  end
end
