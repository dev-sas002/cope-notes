require 'rails_helper'

RSpec.describe Api::V1::SubscribersController, type: :controller do
  let(:default_headers) do
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  let(:subscriber) { create(:subscriber) }

  describe '#index' do
    it 'returns success' do
      request.headers.merge!(default_headers)

      get :index
      expect(response).to be_successful
    end
  end

  describe '#show' do
    it 'returns success' do
      request.headers.merge!(default_headers)

      get :show, params: { id: subscriber.id }
      expect(response).to be_successful
    end
  end

  describe '#create' do
    let(:params) do
      {
        subscriber: {
          name: 'example name',
          email: 'example@text.com'
        }
      }
    end

    it 'creates a subscriber and returns created' do
      request.headers.merge!(default_headers)

      expect { post :create, params: params }
        .to change { Subscriber.count }.by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe '#update' do
    let(:params) do
      {
        subscriber: {
          id: subscriber.id,
          is_active: false
        }
      }
    end

    it 'toggles active state' do
      request.headers.merge!(default_headers)

      expect { patch :update, params: params.merge(id: subscriber.id) }
        .to change { subscriber.reload.is_active }.from(true)
        .to(false)
      expect(response).to be_successful
    end
  end

  describe '#destroy' do
    let!(:existing_subscriber) { create(:subscriber) }

    it 'deletes the subscriber and returns no content' do
      request.headers.merge!(default_headers)

      expect { delete :destroy, params: { id: existing_subscriber.id } }
        .to change { Subscriber.count }.by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'also removes the delivery records for that subscriber' do
      create(:subscriber_email, subscriber: existing_subscriber)
      request.headers.merge!(default_headers)

      expect { delete :destroy, params: { id: existing_subscriber.id } }
        .to change { SubscriberEmail.count }.by(-1)
    end
  end

  describe '#show with invalid id' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      get :show, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#show payload' do
    it 'serializes the subscriber and the messages already received' do
      subscriber_email = create(:subscriber_email)
      request.headers.merge!(default_headers)

      get :show, params: { id: subscriber_email.subscriber_id }
      body = response.parsed_body

      expect(body.keys).to contain_exactly('id', 'name', 'email', 'is_active', 'last_delivered_at', 'messages')
      expect(body['messages'].first['id']).to eq(subscriber_email.message_id)
    end
  end

  describe '#create with invalid params' do
    it 'returns unprocessable entity for a malformed email' do
      request.headers.merge!(default_headers)

      expect { post :create, params: { subscriber: { name: 'example', email: 'nope' } } }
        .not_to change { Subscriber.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to have_key('email')
    end

    it 'returns unprocessable entity for an address that already subscribed' do
      existing = create(:subscriber)
      request.headers.merge!(default_headers)

      expect { post :create, params: { subscriber: { name: 'copy', email: existing.email.upcase } } }
        .not_to change { Subscriber.count }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns bad request when the subscriber key is missing' do
      request.headers.merge!(default_headers)

      post :create, params: {}
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to have_key('error')
    end
  end

  describe '#update on an unknown subscriber' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      patch :update, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#destroy with invalid id' do
    it 'returns not found' do
      request.headers.merge!(default_headers)

      delete :destroy, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end
end
