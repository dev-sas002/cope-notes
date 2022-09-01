# frozen_string_literal: true

module Api
  module V1
    # Operational view of the delivery pipeline - what is configured, how many
    # subscribers are waiting, and what happened to the notes already sent.
    class DeliveriesController < BaseController
      # GET /api/v1/deliveries/stats
      def stats
        render json: Deliveries::Stats.call
      end
    end
  end
end
