# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[create update destroy]

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
