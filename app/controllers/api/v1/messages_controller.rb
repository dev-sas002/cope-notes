# frozen_string_literal: true

class Api::V1::MessagesController < Api::V1::BaseController
  before_action :set_message, only: %i[show edit update destroy]

  # GET /messages
  def index
    @messages = Message.includes(:subscribers).all
    render json: @messages, each_serializer: MessageSerializer
  end

  # GET /messages/1
  def show
    render json: @message, serializer: MessageSerializer
  end

  # POST /messages
  def create
    @message = Message.new(message_params)

    if @message.save
      render json: @message, serializer: MessageSerializer, status: :created
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /messages/1
  def update
    if @message.update(message_params)
      render json: @message, serializer: MessageSerializer
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  # DELETE /messages/1 or /messages/1.json
  def destroy
    @message.destroy

    head :no_content
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.includes(:subscribers).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def message_params
    params.require(:message).permit(:text)
  end
end
