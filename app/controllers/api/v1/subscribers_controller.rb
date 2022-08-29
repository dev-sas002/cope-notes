# frozen_string_literal: true

class Api::V1::SubscribersController < Api::V1::BaseController
  before_action :set_subscriber, only: %i[show edit update destroy]

  # GET /subscribers
  def index
    @subscribers = Subscriber.includes(:messages).all
    render json: @subscribers, each_serializer: SubscriberSerializer
  end

  # GET /subscribers/1
  def show
    render json: @subscriber, serializer: SubscriberSerializer
  end

  # POST /subscribers
  def create
    @subscriber = Subscriber.new(subscriber_params)

    if @subscriber.save
      render json: @subscriber, serializer: SubscriberSerializer, status: :created
    else
      render json: @subscriber.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /subscribers/1
  def update
    if @subscriber.change_status
      render json: @subscriber, serializer: SubscriberSerializer
    else
      render json: @subscriber.errors, status: :unprocessable_entity
    end
  end

  # DELETE /subscribers/1
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

  # Only allow a list of trusted parameters through.
  def subscriber_params
    params.require(:subscriber).permit(:email, :name)
  end
end
