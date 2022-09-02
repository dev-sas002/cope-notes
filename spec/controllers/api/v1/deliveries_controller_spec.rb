require 'rails_helper'

RSpec.describe Api::V1::DeliveriesController, type: :controller do
  describe '#stats' do
    it 'reports the pipeline configuration and current counts' do
      subscriber = create(:subscriber, is_active: true)
      create(:subscriber, is_active: false)
      create(:subscriber_email, subscriber: subscriber, message: create(:message))

      get :stats

      body = response.parsed_body
      expect(response).to be_successful
      expect(body['channel']).to eq('email')
      expect(body['selection_strategy']).to eq('random_unsent')
      expect(body['subscribers']).to include('total' => 2, 'active' => 1)
      expect(body['deliveries']).to include('total' => 1)
      expect(body['deliveries']['by_status']).to eq('delivered' => 1)
    end

    it 'works on an empty install' do
      get :stats

      expect(response).to be_successful
      expect(response.parsed_body['deliveries']['total']).to eq(0)
    end
  end
end
