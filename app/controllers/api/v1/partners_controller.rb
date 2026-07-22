module Api
  module V1
    class PartnersController < BaseController
      # Vitrine pública de parceiros, exibida em telas de login/cadastro antes
      # da autenticação — mas autenticado (usuário já logado no app) mostra o
      # catálogo escopado à própria organização, não o agregado público.
      skip_before_action :authenticate_request!, only: %i[index]
      before_action :attempt_authentication!, only: %i[index]
      before_action -> { require_role!(:admin) }, only: %i[create update destroy]

      # GET /api/v1/partners
      #
      # Pré-autenticação (vitrine pública em /login e /cadastro): mostra o
      # catálogo agregado de todas as organizações — só 4 parceiros hoje,
      # baixo risco (parceria comercial curada, não dado de usuário), e
      # evita inventar um conceito de "destaque" cross-org só pra isso.
      # Autenticado: escopado à própria organização (catálogo privado).
      def index
        partners = current_user ? partner_scope : Partner.all
        partners = partners.order(:category, :name)
        partners = partners.where(category: params[:category]) if params[:category].present?
        render_data(partners.map { |p| PartnerSerializer.new(p).as_json })
      end

      # POST /api/v1/partners
      def create
        partner = Partner.new(partner_params)
        partner.organization_id = current_user.organization_id
        partner.save!
        audit!("partner.create", record: partner)
        render_data(PartnerSerializer.new(partner).as_json, status: :created)
      end

      # PATCH/PUT /api/v1/partners/:id
      def update
        partner = Partner.find(params[:id])
        authorize_organization!(partner)
        return if performed?

        partner.update!(partner_params)
        audit!("partner.update", record: partner)
        render_data(PartnerSerializer.new(partner).as_json)
      end

      # DELETE /api/v1/partners/:id
      def destroy
        partner = Partner.find(params[:id])
        authorize_organization!(partner)
        return if performed?

        partner.destroy!
        audit!("partner.destroy", record: partner)
        head :no_content
      end

      private

      def partner_params
        params.permit(:name, :logo_url, :category, :description, :discount_details, :coupon, :link)
      end
    end
  end
end
