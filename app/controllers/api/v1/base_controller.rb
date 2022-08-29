# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[create update destroy]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(error)
    render json: { error: error.message }, status: :not_found
  end
end
