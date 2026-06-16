module Api
  module V1
    class BaseController < ApplicationController
      include Authenticable
      include Authorizable
      include Auditable

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

      private

      def render_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Standard JSON:API-like envelope used across the API.
      def render_data(data, meta: nil, status: :ok)
        body = { data: data }
        body[:meta] = meta if meta
        render json: body, status: status
      end
    end
  end
end
