module Api
  module V1
    class PushSubscriptionsController < BaseController
      # POST /api/v1/push_subscriptions
      def create
        subscription = current_user.push_subscriptions.find_or_initialize_by(
          endpoint: subscription_params[:endpoint]
        )
        subscription.assign_attributes(
          p256dh_key: subscription_params.dig(:keys, :p256dh),
          auth_key: subscription_params.dig(:keys, :auth),
          user_agent: request.user_agent
        )
        subscription.save!
        audit!("push_subscription.create", record: subscription)
        render_data(PushSubscriptionSerializer.new(subscription).as_json, status: :created)
      end

      # DELETE /api/v1/push_subscriptions
      def destroy
        subscription = current_user.push_subscriptions.find_by(endpoint: subscription_params[:endpoint])
        subscription&.destroy
        head :no_content
      end

      private

      def subscription_params
        params.permit(:endpoint, keys: %i[p256dh auth])
      end
    end
  end
end
