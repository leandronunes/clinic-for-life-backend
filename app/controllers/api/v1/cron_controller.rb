module Api
  module V1
    # Endpoints internos chamados por automação (GitHub Actions agendado —
    # ver .github/workflows/schedule_mark_missed.yml), nunca por um usuário
    # logado. Herda direto de ApplicationController (não BaseController):
    # sem JWT de usuário aqui, é uma chamada servidor-a-servidor autenticada
    # por token compartilhado.
    class CronController < ApplicationController
      before_action :authenticate_cron!

      # POST /api/v1/internal/cron/mark_missed_sessions
      def mark_missed_sessions
        updated = ScheduleMissedMarkerService.call
        render json: { data: { updated: updated } }
      end

      private

      def authenticate_cron!
        header = request.headers["Authorization"].to_s
        token = header.split(" ").last.to_s
        expected = ENV.fetch("INTERNAL_CRON_TOKEN", nil)

        valid = expected.present? && token.present? &&
                ActiveSupport::SecurityUtils.secure_compare(token, expected)
        render json: { error: "Unauthorized" }, status: :unauthorized unless valid
      end
    end
  end
end
