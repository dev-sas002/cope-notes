# frozen_string_literal: true

module Api
  module V1
    class SubscribersController < BaseController
      before_action :set_subscriber, only: %i[show update destroy]

      # GET /api/v1/subscribers
      def index
        render json: Subscriber.includes(:messages).order(:id), each_serializer: SubscriberSerializer
      end

      # GET /api/v1/subscribers/:id
      def show
        render json: @subscriber, serializer: SubscriberSerializer
      end

      # POST /api/v1/subscribers
      def create
        @subscriber = Subscriber.new(subscriber_params)

        if @subscriber.save
          render json: @subscriber, serializer: SubscriberSerializer, status: :created
        else
          render json: @subscriber.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/subscribers/:id - toggles the subscription on or off.
      def update
        if @subscriber.change_status
          render json: @subscriber, serializer: SubscriberSerializer
        else
          render json: @subscriber.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/subscribers/:id
      def destroy
        if @subscriber.destroy
          head :no_content
        else
          render json: @subscriber.errors, status: :unprocessable_entity
        end
      end

      private

      def set_subscriber
        @subscriber = Subscriber.includes(:messages).find(params[:id])
      end

      def subscriber_params
        params.require(:subscriber).permit(:email, :name)
      end
    end
  end
end
