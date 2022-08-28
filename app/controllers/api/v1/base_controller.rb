# frozen_string_literal: true

module Api
  module V1
    # JSON only: no sessions, cookies or CSRF tokens, so it derives from
    # ActionController::API rather than the HTML ApplicationController.
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_not_found(error)
        render json: { error: error.message }, status: :not_found
      end

      def render_bad_request(error)
        render json: { error: error.message }, status: :bad_request
      end
    end
  end
end
