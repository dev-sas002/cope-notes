# frozen_string_literal: true

module Api
  module V1
    class MessagesController < BaseController
      before_action :set_message, only: %i[show update destroy]

      # GET /api/v1/messages
      def index
        render json: messages_scope, each_serializer: MessageSerializer
      end

      # GET /api/v1/messages/:id
      def show
        render json: @message, serializer: MessageSerializer
      end

      # POST /api/v1/messages
      def create
        message = Message.new

        if Notes::SaveNote.call(message, message_params)
          render json: message, serializer: MessageSerializer, status: :created
        else
          render json: message.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/messages/:id
      def update
        if Notes::SaveNote.call(@message, message_params)
          render json: @message, serializer: MessageSerializer
        else
          render json: @message.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/messages/:id
      def destroy
        @message.destroy

        head :no_content
      end

      private

      # `review_status=flagged` is how an editor finds the notes screening wants
      # a human to look at.
      def messages_scope
        scope = Message.includes(:subscribers).order(:id)
        review_status = params[:review_status].presence
        return scope unless Message::REVIEW_STATUSES.include?(review_status)

        scope.where(review_status: review_status)
      end

      def set_message
        @message = Message.includes(:subscribers).find(params[:id])
      end

      def message_params
        params.require(:message).permit(:text)
      end
    end
  end
end
